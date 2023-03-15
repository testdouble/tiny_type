require "spec_helper"

class BenchmarkTestClass
  include MiniType

  def self.method_using_accepts(foo:, bar:)
    accepts { {foo: Integer, bar: [String, NilClass]} }
    true
  end

  def self.bare_method(foo:, bar:)
    true
  end
end

BENCHMARK_ITERATION_COUNT = 1_000_000

RSpec.describe MiniType do
  before(:all) do
    @benchmarks = {}
  end

  after(:all) do
    DELAYED_OUTPUT.puts "\n\nBenchmark Results:"
    @benchmarks.each do |test_name, result|
      DELAYED_OUTPUT.puts test_name.ljust(40) + ": " + result.to_s
    end
  end

  describe "benchmark" do
    it "benchmarks MiniType.accepts" do
      @benchmarks["typed method call using MiniType.accepts"] = Benchmark.measure do
        BENCHMARK_ITERATION_COUNT.times do |id|
          BenchmarkTestClass.method_using_accepts(foo: 123, bar: "123")
        end
      end
    end

    it "benchmarks insertion via raw SQL" do
      @benchmarks["un-typed method call"] = Benchmark.measure do
        BENCHMARK_ITERATION_COUNT.times do |id|
          BenchmarkTestClass.bare_method(foo: 123, bar: "123")
        end
      end
    end
  end
end
