require 'rspec/core/rake_task'

# Default task
task default: :test

# Run all tests
desc "Run all tests"
task :test do
  Rake::Task['test:unit'].invoke
  Rake::Task['test:integration'].invoke
  Rake::Task['test:docker'].invoke
end

namespace :test do
  desc "Run unit tests"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
    t.rspec_opts = '--format documentation'
  end

  desc "Run integration tests"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
    t.rspec_opts = '--format documentation'
  end

  desc "Run Docker-based tests"
  RSpec::Core::RakeTask.new(:docker) do |t|
    t.pattern = 'spec/entrypoint/**/*_spec.rb'
    t.rspec_opts = '--format documentation'
  end

  desc "Run all tests"
  RSpec::Core::RakeTask.new(:all) do |t|
    t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = '--format documentation'
  end
end

# Linting tasks
namespace :lint do
  desc "Run shellcheck on shell scripts"
  task :shell do
    sh "shellcheck entrypoint.sh"
  end

  desc "Run bashate on shell scripts"
  task :bashate do
    sh "bashate -i E003,E006 entrypoint.sh"
  end

  desc "Run rubocop on Ruby files"
  task :ruby do
    sh "rubocop"
  end

  desc "Run all linting tasks"
  task :all do
    Rake::Task['lint:shell'].invoke
    Rake::Task['lint:bashate'].invoke
    Rake::Task['lint:ruby'].invoke
  end
end

# Docker tasks
namespace :docker do
  desc "Build Docker image"
  task :build do
    sh "docker build -t image-resizer-test ."
  end

  desc "Test Docker image"
  task :test => :build do
    sh "docker run --rm image-resizer-test 100 100 /workspace/test/ 50%"
  end
end