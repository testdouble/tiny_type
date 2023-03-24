require "spec_helper"

class ProfileTestClass
  include TinyType

  def self.typed_method(foo:, bar:, baz:)
    accepts { {foo: String, bar: [Integer, Float], baz: Array} }
    true
  end
end

PROFILE_ITERATION_COUNT = 100_000

RSpec.describe TinyType do
  describe "profile" do
    it "profiles TinyType.accepts" do
      profile = RubyProf.profile do
        PROFILE_ITERATION_COUNT.times do
          ProfileTestClass.typed_method(foo: "abc", bar: 123, baz: [1, 2, 3])
        end
      end

      DELAYED_OUTPUT.puts "\n\nProfile Results:"
      printer = RubyProf::FlatPrinter.new(profile)
      printer.print(DELAYED_OUTPUT, min_percent: 2)
    end
  end
end
