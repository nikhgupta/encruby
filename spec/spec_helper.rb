require "simplecov"
require "bundler/setup"
require "encruby"

pattern = File.join(File.dirname(__FILE__), "support", "**", "*.rb")
Dir.glob(pattern).each{|f| require f}

RSpec.configure do |config|
  config.include Encruby::RSpecHelper

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
