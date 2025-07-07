require 'spec_helper'
require 'yaml'
require 'json'
require 'docker'

describe 'GitHub Action Integration Tests' do
  def imagemagick_command
    @imagemagick_command ||= if system('which magick > /dev/null 2>&1')
                               'magick'
                             elsif system('which convert > /dev/null 2>&1')
                               'convert'
                             else
                               raise 'Neither magick nor convert command is available. Please install ImageMagick.'
                             end
  end
  describe 'action.yml validation' do
    before(:all) do
      @action_config = YAML.load_file('action.yml')
    end

    it 'has required metadata' do
      expect(@action_config).to have_key('name')
      expect(@action_config).to have_key('description')
      expect(@action_config).to have_key('inputs')
      expect(@action_config).to have_key('outputs')
      expect(@action_config).to have_key('runs')
    end

    it 'has correct input definitions' do
      inputs = @action_config['inputs']
      expect(inputs).to have_key('target')
      expect(inputs).to have_key('dimensions')
      expect(inputs).to have_key('widthLimit')
      expect(inputs).to have_key('HeightLimit')

      expect(inputs['target']['required']).to be true
      expect(inputs['dimensions']['required']).to be true
      expect(inputs['widthLimit']['required']).to be true
      expect(inputs['HeightLimit']['required']).to be true
    end

    it 'has correct output definitions' do
      outputs = @action_config['outputs']
      expect(outputs).to have_key('images_changed')
      expect(outputs).to have_key('csv_images_changed')
    end

    it 'uses Docker runtime' do
      expect(@action_config['runs']['using']).to eq('docker')
      expect(@action_config['runs']['image']).to eq('Dockerfile')
    end
  end

  describe 'Docker integration' do
    before(:all) do
      @temp_dir = Dir.mktmpdir
      @test_images_dir = File.join(@temp_dir, 'test-images')
      Dir.mkdir(@test_images_dir)

      # Create test images
      `#{imagemagick_command} -size 1200x800 xc:red #{@test_images_dir}/large.jpg`
      `#{imagemagick_command} -size 500x400 xc:blue #{@test_images_dir}/small.jpg`
      `#{imagemagick_command} -size 1024x1024 xc:green #{@test_images_dir}/square.png`
    end

    after(:all) do
      FileUtils.remove_entry(@temp_dir)
    end

    it 'builds Docker image successfully' do
      image = Docker::Image.build_from_dir('.', { 't' => 'test-image-resizer' })
      expect(image).not_to be_nil
      expect(image.id).not_to be_empty
    end

    it 'runs Docker container with correct parameters' do
      container = Docker::Container.create(
        'Image' => 'test-image-resizer',
        'Cmd' => ['1000', '700', '/workspace/images/', '75%'],
        'HostConfig' => {
          'Binds' => ["#{@test_images_dir}:/workspace/images"]
        }
      )
      
      container.start
      exit_status = container.wait['StatusCode']
      output = container.logs(stdout: true, stderr: true)
      container.remove
      
      expect(exit_status).to eq(0)
      expect(output).to include('Width Limit: 1000')
      expect(output).to include('Height Limit: 700')
    end

    it 'processes images correctly in Docker' do
      # Copy test images to temporary directory
      temp_test_dir = Dir.mktmpdir
      `cp -r #{@test_images_dir}/* #{temp_test_dir}/`

      container = Docker::Container.create(
        'Image' => 'test-image-resizer',
        'Cmd' => ['1000', '700', '/workspace/images/', '75%'],
        'HostConfig' => {
          'Binds' => ["#{temp_test_dir}:/workspace/images"]
        }
      )
      
      container.start
      exit_status = container.wait['StatusCode']
      container.remove
      
      expect(exit_status).to eq(0)

      # Check that large image was resized
      large_width = `identify -format "%w" #{temp_test_dir}/large.jpg`.strip.to_i
      large_height = `identify -format "%h" #{temp_test_dir}/large.jpg`.strip.to_i
      expect(large_width).to be <= 1000
      expect(large_height).to be <= 700

      # Check that small image was not resized
      small_width = `identify -format "%w" #{temp_test_dir}/small.jpg`.strip.to_i
      small_height = `identify -format "%h" #{temp_test_dir}/small.jpg`.strip.to_i
      expect(small_width).to eq(500)
      expect(small_height).to eq(400)

      FileUtils.remove_entry(temp_test_dir)
    end
  end

  describe 'GitHub Actions environment simulation' do
    before do
      @temp_dir = Dir.mktmpdir
      @test_images_dir = File.join(@temp_dir, 'images')
      Dir.mkdir(@test_images_dir)

      # Create test images
      `#{imagemagick_command} -size 1500x1000 xc:red #{@test_images_dir}/oversized.jpg`
      `#{imagemagick_command} -size 800x600 xc:blue #{@test_images_dir}/normal.jpg`
    end

    after do
      FileUtils.remove_entry(@temp_dir)
    end

    it 'produces GitHub Actions compatible output' do
      result = `bash entrypoint.sh 1024 768 #{@test_images_dir}/ 80% 2>&1`
      expect($?.exitstatus).to eq(0)

      # Check for GitHub Actions output format
      expect(result).to match(/::set-output name=images_changed::/)
      expect(result).to match(/::set-output name=csv_images_changed::/)
    end

    it 'handles CSV output with proper escaping' do
      result = `bash entrypoint.sh 1024 768 #{@test_images_dir}/ 80% 2>&1`
      expect($?.exitstatus).to eq(0)

      # Extract CSV output
      csv_line = result.lines.find { |line| line.include?('::set-output name=csv_images_changed::') }
      expect(csv_line).not_to be_nil
      expect(csv_line).to include('%0A') # Newline encoding
    end

    it 'handles no changes scenario' do
      # Create only small images
      `#{imagemagick_command} -size 500x400 xc:green #{@test_images_dir}/small1.jpg`
      `#{imagemagick_command} -size 600x500 xc:yellow #{@test_images_dir}/small2.jpg`

      result = `bash entrypoint.sh 2000 1000 #{@test_images_dir}/ 80% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include('No Images Changed')
    end
  end

  describe 'action performance and reliability' do
    it 'handles large number of images' do
      temp_dir = Dir.mktmpdir
      test_images_dir = File.join(temp_dir, 'bulk-test')
      Dir.mkdir(test_images_dir)

      # Create 10 test images
      10.times do |i|
        `#{imagemagick_command} -size 1200x800 xc:red #{test_images_dir}/test#{i}.jpg`
      end

      start_time = Time.now
      result = `bash entrypoint.sh 1000 700 #{test_images_dir}/ 75% 2>&1`
      end_time = Time.now

      expect($?.exitstatus).to eq(0)
      expect(end_time - start_time).to be < 30 # Should complete within 30 seconds
      expect(result).to include('Image count in directory: 10')

      FileUtils.remove_entry(temp_dir)
    end

    it 'handles different image formats correctly' do
      temp_dir = Dir.mktmpdir
      test_images_dir = File.join(temp_dir, 'format-test')
      Dir.mkdir(test_images_dir)

      # Create images with different formats
      `#{imagemagick_command} -size 1200x800 xc:red #{test_images_dir}/test.jpg`
      `#{imagemagick_command} -size 1200x800 xc:blue #{test_images_dir}/test.jpeg`
      `#{imagemagick_command} -size 1200x800 xc:green #{test_images_dir}/test.png`

      result = `bash entrypoint.sh 1000 700 #{test_images_dir}/ 75% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include('Image count in directory: 3')

      FileUtils.remove_entry(temp_dir)
    end
  end
end
