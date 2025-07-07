require "spec_helper"

describe "entrypoint.sh unit tests" do
  describe "parameter validation" do
    it "should exit with error when no parameters provided" do
      result = `bash entrypoint.sh 2>&1`
      expect($?.exitstatus).to eq(1)
      expect(result).to include("Please provide all variables")
    end

    it "should exit with error when missing parameters" do
      result = `bash entrypoint.sh 100 2>&1`
      expect($?.exitstatus).to eq(1)
      expect(result).to include("Please provide all variables")
    end

    it "should exit with error when directory does not exist" do
      result = `bash entrypoint.sh 100 100 /nonexistent/ 50% 2>&1`
      expect($?.exitstatus).to eq(1)
      expect(result).to include("Error: /nonexistent/ does not exist")
    end
  end

  describe "parameter parsing" do
    before(:each) do
      @temp_dir = Dir.mktmpdir
      # Create a test image
      `convert -size 100x100 xc:red #{@temp_dir}/test.jpg`
    end

    after(:each) do
      FileUtils.remove_entry(@temp_dir)
    end

    it "should correctly parse width and height limits" do
      result = `bash entrypoint.sh 200 200 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("Width Limit: 200")
      expect(result).to include("Height Limit: 200")
    end

    it "should correctly identify target directory" do
      result = `bash entrypoint.sh 200 200 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("Given directory: #{@temp_dir}/")
    end

    it "should find images in directory" do
      result = `bash entrypoint.sh 200 200 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("Image count in directory: 1")
    end
  end

  describe "image processing logic" do
    before(:each) do
      @temp_dir = Dir.mktmpdir
    end

    after(:each) do
      FileUtils.remove_entry(@temp_dir)
    end

    it "should not resize images under the limit" do
      # Create small image
      `convert -size 50x50 xc:blue #{@temp_dir}/small.jpg`
      
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("is not Oversized, no mogrify needed")
      expect(result).to include("No Images Changed")
    end

    it "should resize images over the width limit" do
      # Create wide image
      `convert -size 200x50 xc:green #{@temp_dir}/wide.jpg`
      
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("is Oversized")
      expect(result).to include("mogrify complete")
    end

    it "should resize images over the height limit" do
      # Create tall image
      `convert -size 50x200 xc:yellow #{@temp_dir}/tall.jpg`
      
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("is Oversized")
      expect(result).to include("mogrify complete")
    end

    it "should handle empty directory" do
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(1)
      expect(result).to include("No images found in #{@temp_dir}/")
    end

    it "should handle multiple image formats" do
      # Create images with different formats
      `convert -size 150x150 xc:red #{@temp_dir}/test.jpg`
      `convert -size 150x150 xc:blue #{@temp_dir}/test.png`
      `convert -size 150x150 xc:green #{@temp_dir}/test.jpeg`
      
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("Image count in directory: 3")
    end
  end

  describe "output formatting" do
    before(:each) do
      @temp_dir = Dir.mktmpdir
      # Create an oversized image
      `convert -size 200x200 xc:red #{@temp_dir}/oversized.jpg`
    end

    after(:each) do
      FileUtils.remove_entry(@temp_dir)
    end

    it "should generate correct GitHub Actions output format" do
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to include("::set-output name=images_changed::")
      expect(result).to include("::set-output name=csv_images_changed::")
    end

    it "should include image dimensions in output" do
      result = `bash entrypoint.sh 100 100 #{@temp_dir}/ 50% 2>&1`
      expect($?.exitstatus).to eq(0)
      expect(result).to match(/old size: \d+ x \d+, new size: \d+ x \d+/)
    end
  end
end