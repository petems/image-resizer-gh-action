# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2025-07-07

### Added
- Comprehensive testing suite with RSpec and Serverspec
- Integration tests with actual image processing
- Docker-based testing infrastructure
- GitHub Actions CI/CD pipeline

### Changed
- Migrated from Travis CI to GitHub Actions
- Refactored Docker command execution to use Docker gem
- Updated Ruby version to 3.2 for better compatibility
- Improved GitHub Actions output syntax

### Fixed
- Fixed capitalization issues in documentation and code
- Fixed failing GitHub Actions workflow
- Improved error handling in entrypoint script

### Infrastructure
- Added Dockerfile.serverspec for testing
- Enhanced Rakefile with proper test tasks
- Updated Gemfile with testing dependencies

## [1.0.0] - 2023-XX-XX

### Added
- Initial release of Image Resizer GitHub Action
- Support for resizing images based on width and height limits
- CSV and HTML output formats for changed images
- Multi-line output workaround for GitHub Actions
- Directory validation and error handling
- Support for JPG, JPEG, and PNG formats

### Features
- In-place image resizing using ImageMagick's mogrify
- Configurable resize parameters (percentage, dimensions)
- Batch processing of images in specified directories
- Detailed output showing old and new image dimensions 