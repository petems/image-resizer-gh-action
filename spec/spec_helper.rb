require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'pathname'

# Set up the environment for tests
ENV['RSPEC_RUNNING'] = 'true'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :defined
  Kernel.srand config.seed

  # Ensure ImageMagick is available for tests
  config.before(:suite) do
    # Check if ImageMagick is available
    unless system("which convert > /dev/null 2>&1")
      puts "WARNING: ImageMagick (convert) not found. Some tests may fail."
    end
    
    unless system("which identify > /dev/null 2>&1")
      puts "WARNING: ImageMagick (identify) not found. Some tests may fail."
    end
    
    unless system("which mogrify > /dev/null 2>&1")
      puts "WARNING: ImageMagick (mogrify) not found. Some tests may fail."
    end
  end

  # Clean up any temporary files after each test
  config.after(:each) do
    # Clean up any leftover temporary files
    Dir.glob('/tmp/test-images-*').each do |dir|
      FileUtils.remove_entry(dir, force: true) if File.directory?(dir)
    end
  end
end

# Helper methods for tests
def create_test_image(path, width, height, color = 'red')
  `convert -size #{width}x#{height} xc:#{color} #{path}`
  raise "Failed to create test image #{path}" unless $?.exitstatus == 0
end

def get_image_dimensions(path)
  width = `identify -format "%w" #{path}`.strip.to_i
  height = `identify -format "%h" #{path}`.strip.to_i
  [width, height]
end

def image_exists?(path)
  File.exist?(path) && File.size(path) > 0
end

def run_entrypoint(width_limit, height_limit, directory, dimensions)
  `bash entrypoint.sh #{width_limit} #{height_limit} #{directory} #{dimensions} 2>&1`
end

def create_temp_image_dir
  temp_dir = Dir.mktmpdir("test-images-")
  temp_dir
end