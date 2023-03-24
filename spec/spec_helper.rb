# frozen_string_literal: true

require "tiny_type"
require "benchmark"
require "ruby-prof"
require "stringio"

DELAYED_OUTPUT = StringIO.new

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:suite) do
    DELAYED_OUTPUT.rewind
    puts DELAYED_OUTPUT.read
  end
end
