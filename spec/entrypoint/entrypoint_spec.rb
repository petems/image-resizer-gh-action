require "serverspec"
require "docker"

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
    describe command('mkdir -p images/ && convert -size 32x32 xc:black ./images/black-box-32.jpg') do
      its(:exit_status) { should eq 0 }
    end

    describe file('./images/black-box-32.jpg') do
      it { should exist }
      its(:size) { should eql 165 }
    end

    describe command('bash -x ./entrypoint.sh 31 31 ./images/ 50%') do
      its(:stdout) { should match '::set-output name=images_changed::<br />./images/black-box-32.jpg - old size: 32 x 32, new size: 16 x 16' }
      its(:exit_status) { should eq 0 }
    end
  end

  context 'entrypoint.sh with non-existance directory' do
    describe command('bash -x ./entrypoint.sh 31 31 ./notexist/ 50%') do
      its(:stdout) { should match 'Error: ./notexist/ does not exist' }
      its(:exit_status) { should eq 1 }
    end
  end
end
