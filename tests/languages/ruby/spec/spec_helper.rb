require "bundler/setup"

require "simplecov"
require "simplecov-html"
require "simplecov_json_formatter"
# SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
])
SimpleCov.start do
  enable_coverage :branch
end

require "fizzbuzz"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
