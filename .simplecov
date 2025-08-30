# SimpleCov configuration file for ATS application
# This file provides default configuration that can be overridden in spec_helper.rb

SimpleCov.configure do
  # Enable branch coverage for more comprehensive analysis
  enable_coverage :branch

  # Primary coverage threshold
  minimum_coverage 85

  # File-level minimum coverage
  minimum_coverage_by_file 70

  # Refuse coverage below this level per file
  refuse_coverage_drop_above 2.0

  # Command name for this run (useful for merging results)
  command_name ENV.fetch("COVERAGE_COMMAND", "rspec")

  # Coverage output directory
  coverage_dir "coverage"

  # Merge timeout for parallel runs (in seconds)
  merge_timeout 3600

  # Always merge results from parallel test runs
  use_merging true

  # Clean coverage directory on start
  clean_directory_on_start true
end

# Performance configuration
SimpleCov.configure do
  # Skip slow operations in development
  skip_token_coverage true if ENV["RAILS_ENV"] == "development"

  # Reduce memory usage for large test suites
  maximum_coverage_drop 2.0
end

# Formatting options
SimpleCov.configure do
  # Format percentages
  precision 2

  # Show which lines are covered in terminal
  print_missed_lines ENV["COVERAGE_VERBOSE"] == "true"
end

# Branch coverage configuration for Rails 8 compatibility
if SimpleCov.respond_to?(:branch_coverage?)
  SimpleCov.configure do
    branch_coverage true
  end
end
