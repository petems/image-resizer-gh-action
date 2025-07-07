require "serverspec"
require "docker"
require "spec_helper"

describe "Dockerfile" do
  before(:all) do
    @image = Docker::Image.build_from_dir('.',
      {
        'dockerfile' => 'Dockerfile.serverspec'
      }
    )

    set :os, family: :alpine
    set :backend, :docker
    set :docker_image, @image.id
  end

  context 'entrypoint.sh with valid file' do

    describe command('mkdir -p ./images/') do
      its(:exit_status) { should eq 0 }
    end

    describe file('./images/') do
      it { should be_directory }
    end

    describe command('convert -size 32x32 xc:black ./images/black-box-32.jpg') do
      its(:exit_status) { should eq 0 }
    end

    describe file('./images/black-box-32.jpg') do
      it { should exist }
      its(:size) { should eql 165 }
    end

    describe command('bash -x ./entrypoint.sh 31 31 ./images/ 50%') do
      its(:stdout) { should match '::set-output name=images_changed::<br />./images/black-box-32.jpg - old size: 32 x 32, new size: 16 x 16' }
      its(:stdout) { should match '::set-output name=csv_images_changed::Image path, Old size, New size%0A./images/black-box-32.jpg, 32 x 32, 16 x 16' }
      its(:exit_status) { should eq 0 }
    end
  end

  context 'entrypoint.sh with non-existance directory' do
    describe command('bash -x ./entrypoint.sh 31 31 ./notexist/ 50%') do
      its(:stdout) { should match 'Error: ./notexist/ does not exist' }
      its(:exit_status) { should eq 1 }
    end
  end

  context 'entrypoint.sh with multiple image formats' do
    describe command('mkdir -p test-images/ && convert -size 100x100 xc:red ./test-images/test.jpg && convert -size 100x100 xc:blue ./test-images/test.png && convert -size 100x100 xc:green ./test-images/test.jpeg') do
      its(:exit_status) { should eq 0 }
    end

    describe command('bash -x ./entrypoint.sh 50 50 ./test-images/ 75%') do
      its(:stdout) { should match 'Image count in directory: 3' }
      its(:exit_status) { should eq 0 }
    end
  end

  context 'entrypoint.sh with images under limit' do
    describe command('mkdir -p small-images/ && convert -size 30x30 xc:yellow ./small-images/small.jpg') do
      its(:exit_status) { should eq 0 }
    end

    describe command('bash -x ./entrypoint.sh 50 50 ./small-images/ 75%') do
      its(:stdout) { should match 'is not Oversized, no mogrify needed' }
      its(:stdout) { should match 'No Images Changed' }
      its(:exit_status) { should eq 0 }
    end
  end
end
