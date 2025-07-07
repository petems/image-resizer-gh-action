require 'spec_helper'
require 'yaml'
require 'json'
require 'docker'

describe 'GitHub Action Integration Tests' do
  before(:all) do
    # Build Docker image for all tests
    @docker_image = Docker::Image.build_from_dir('.', 't' => 'test-image-resizer')
  end

  def imagemagick_command
    @imagemagick_command ||= if system('which magick > /dev/null 2>&1')
                               'magick'
                             elsif system('which convert > /dev/null 2>&1')
                               'convert'
                             else
                               raise 'Neither magick nor convert command is available. Please install ImageMagick.'
                             end
  end

  shared_examples 'successful container execution' do
    it 'runs successfully' do
      expect(container_result[:exit_code]).to eq(0)
    end

    it 'has no ImageMagick decode delegate errors' do
      no_decode_delegate = container_result[:output].lines.find { |line| line.include?('no decode delegate for this image format') }
      expect(no_decode_delegate).to be_nil
    end

    it 'produces expected output' do
      expected_outputs.each do |expected|
        expect(container_result[:output]).to include(expected)
      end
    end
  end

  shared_context 'docker container execution' do
    let(:container_result) do
      container = Docker::Container.create(
        'Image' => 'test-image-resizer',
        'Cmd' => cmd_args,
        'HostConfig' => {
          'Binds' => [volume_bind]
        }
      )
      
      container.start
      exit_code = container.wait['StatusCode']
      output = container.logs(stdout: true, stderr: true)
      
      # Clean up container
      container.remove
      
      { exit_code: exit_code, output: output }
    end
  end

  after(:all) do
    # Clean up Docker images created during tests
    begin
      image = Docker::Image.get('test-image-resizer')
      image.remove(force: true) if image
    rescue Docker::Error::NotFoundError
      # Image doesn't exist, nothing to clean up
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
    let(:temp_dir) { Dir.mktmpdir }
    let(:test_images_dir) { File.join(temp_dir, 'test-images') }

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
      expect(@docker_image).not_to be_nil
      expect(@docker_image.id).not_to be_empty
    end

    describe 'container execution with parameters' do
      include_context 'docker container execution'

      let(:cmd_args) { ['1000', '700', '/workspace/images/', '75%'] }
      let(:volume_bind) { "#{@test_images_dir}:/workspace/images" }
      let(:expected_outputs) { ['Width Limit: 1000', 'Height Limit: 700'] }

      include_examples 'successful container execution'
    end

    describe 'image processing' do
      let(:temp_test_dir) { Dir.mktmpdir }
      
      before do
        `cp -r #{@test_images_dir}/* #{temp_test_dir}/`
      end
      
      after do
        FileUtils.remove_entry(temp_test_dir)
      end

      include_context 'docker container execution'

      let(:cmd_args) { ['1000', '700', '/workspace/images/', '75%'] }
      let(:volume_bind) { "#{temp_test_dir}:/workspace/images" }

      it 'processes images correctly in Docker' do
        expect(container_result[:exit_code]).to eq(0)

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
      end
    end
  end

  describe 'GitHub Actions environment simulation' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:test_images_dir) { File.join(temp_dir, 'images') }

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

    describe 'GitHub Actions output format' do
      include_context 'docker container execution'

      let(:cmd_args) { ['1024', '768', '/workspace/images/', '80%'] }
      let(:volume_bind) { "#{@test_images_dir}:/workspace/images" }
      let(:expected_outputs) { [/::set-output name=images_changed::/, /::set-output name=csv_images_changed::/] }

      it 'produces GitHub Actions compatible output' do
        expect(container_result[:exit_code]).to eq(0)
        expected_outputs.each do |pattern|
          expect(container_result[:output]).to match(pattern)
        end
      end
    end

    describe 'CSV output handling' do
      include_context 'docker container execution'

      let(:cmd_args) { ['1024', '768', '/workspace/images/', '80%'] }
      let(:volume_bind) { "#{@test_images_dir}:/workspace/images" }

      it 'handles CSV output with proper escaping' do
        expect(container_result[:exit_code]).to eq(0)
        # Extract CSV output
        csv_line = container_result[:output].lines.find { |line| line.include?('::set-output name=csv_images_changed::') }
        expect(csv_line).not_to be_nil
        expect(csv_line).to include('%0A') # Newline encoding
      end
    end

    describe 'no changes scenario' do
      before do
        # Create only small images
        `#{imagemagick_command} -size 500x400 xc:green #{@test_images_dir}/small1.jpg`
        `#{imagemagick_command} -size 600x500 xc:yellow #{@test_images_dir}/small2.jpg`
      end

      include_context 'docker container execution'

      let(:cmd_args) { ['2000', '1000', '/workspace/images/', '80%'] }
      let(:volume_bind) { "#{@test_images_dir}:/workspace/images" }
      let(:expected_outputs) { ['No Images Changed'] }

      include_examples 'successful container execution'
    end
  end

  describe 'action performance and reliability' do
    describe 'large number of images' do
      let(:temp_dir) { Dir.mktmpdir }
      let(:test_images_dir) { File.join(temp_dir, 'bulk-test') }
      
      before do
        Dir.mkdir(test_images_dir)
        # Create 10 test images
        10.times do |i|
          `#{imagemagick_command} -size 1200x800 xc:red #{test_images_dir}/test#{i}.jpg`
        end
      end

      after do
        FileUtils.remove_entry(temp_dir)
      end

      include_context 'docker container execution'

      let(:cmd_args) { ['1000', '700', '/workspace/images/', '75%'] }
      let(:volume_bind) { "#{test_images_dir}:/workspace/images" }
      let(:expected_outputs) { ['Image count in directory: 10'] }

      it 'handles large number of images' do
        start_time = Time.now
        result = container_result
        end_time = Time.now

        expect(result[:exit_code]).to eq(0)
        expect(end_time - start_time).to be < 30 # Should complete within 30 seconds
        expect(result[:output]).to include('Image count in directory: 10')
      end
    end

    describe 'different image formats' do
      let(:temp_dir) { Dir.mktmpdir }
      let(:test_images_dir) { File.join(temp_dir, 'format-test') }
      
      before do
        Dir.mkdir(test_images_dir)
        # Create images with different formats
        `#{imagemagick_command} -size 1200x800 xc:red #{test_images_dir}/test.jpg`
        `#{imagemagick_command} -size 1200x800 xc:blue #{test_images_dir}/test.jpeg`
        `#{imagemagick_command} -size 1200x800 xc:green #{test_images_dir}/test.png`
      end

      after do
        FileUtils.remove_entry(temp_dir)
      end

      include_context 'docker container execution'

      let(:cmd_args) { ['1000', '700', '/workspace/images/', '75%'] }
      let(:volume_bind) { "#{test_images_dir}:/workspace/images" }
      let(:expected_outputs) { ['Image count in directory: 3'] }

      include_examples 'successful container execution'
    end
  end

  describe 'real image acceptance test' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:test_images_dir) { File.join(temp_dir, 'real-image-test') }
    let(:real_image_path) { File.join(File.dirname(__FILE__), 'introRealAnalysisImg.jpg') }
    
    before do
      Dir.mkdir(test_images_dir)
      expect(File.exist?(real_image_path)).to be true
      `cp #{real_image_path} #{test_images_dir}/`
    end

    after do
      FileUtils.remove_entry(temp_dir)
    end

    include_context 'docker container execution'

    let(:cmd_args) { ['700', '900', '/workspace/images/', '80%'] }
    let(:volume_bind) { "#{test_images_dir}:/workspace/images" }

    it 'processes introRealAnalysisImg.jpg without error' do
      # Get original dimensions
      original_width = `identify -format "%w" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i
      original_height = `identify -format "%h" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i

      # Run the resizer with limits that will trigger resizing and 80% scaling
      expect(container_result[:exit_code]).to eq(0)

      # Verify the image still exists and is valid
      expect(File.exist?("#{test_images_dir}/introRealAnalysisImg.jpg")).to be true
      
      # Check that image was resized (80% of original dimensions)
      new_width = `identify -format "%w" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i
      new_height = `identify -format "%h" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i
      
      # Verify dimensions are valid and the image was actually resized
      expect(new_width).to be > 0
      expect(new_height).to be > 0
      expect(new_width).to be < original_width
      expect(new_height).to be < original_height
      
      # Verify the scaling is approximately 80% (allowing for rounding)
      expect(new_width).to be_within(5).of(original_width * 0.8)
      expect(new_height).to be_within(5).of(original_height * 0.8)
    end
  end

  describe 'real image acceptance test' do
    it 'processes introRealAnalysisImg.jpg without error' do
      temp_dir = Dir.mktmpdir
      test_images_dir = File.join(temp_dir, 'real-image-test')
      Dir.mkdir(test_images_dir)

      # Copy the real test image
      real_image_path = File.join(File.dirname(__FILE__), 'introRealAnalysisImg.jpg')
      expect(File.exist?(real_image_path)).to be true
      
      `cp #{real_image_path} #{test_images_dir}/`

      # Get original dimensions
      original_width = `identify -format "%w" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i
      original_height = `identify -format "%h" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i

      # Run the resizer with limits that will trigger resizing and 80% scaling
      result = `bash entrypoint.sh 700 900 #{test_images_dir}/ 80% 2>&1`
      expect($?.exitstatus).to eq(0)

      # Verify the image still exists and is valid
      expect(File.exist?("#{test_images_dir}/introRealAnalysisImg.jpg")).to be true
      
      # Check that image was resized (80% of original dimensions)
      new_width = `identify -format "%w" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i
      new_height = `identify -format "%h" #{test_images_dir}/introRealAnalysisImg.jpg`.strip.to_i
      
      # Verify dimensions are valid and the image was actually resized
      expect(new_width).to be > 0
      expect(new_height).to be > 0
      expect(new_width).to be < original_width
      expect(new_height).to be < original_height
      
      # Verify the scaling is approximately 80% (allowing for rounding)
      expect(new_width).to be_within(5).of(original_width * 0.8)
      expect(new_height).to be_within(5).of(original_height * 0.8)

      FileUtils.remove_entry(temp_dir)
    end
  end
end
