# frozen_string_literal: true

class TestClass
  include TinyType
end

RSpec.describe TinyType do
  describe "VERSION" do
    it "has a version number" do
      expect(TinyType::VERSION).not_to be nil
    end
  end

  describe ".logger=" do
    before { @old_logger = TinyType.logger }
    after { TinyType.logger = @old_logger }

    it "does not raise an error when passed an object that responds to :warn" do
      expect {
        TinyType.logger = double(warn: :foo)
      }.not_to raise_error
    end

    it "raises an error when passed an object that does not respond to :warn" do
      expect {
        TinyType.logger = double
      }.to raise_error("TinyType.logger expects an object that responds to :warn")
    end
  end

  describe ".logger" do
    it "returns a Logger instance by default" do
      expect(TinyType.logger).to be_a(Logger)
    end
  end

  describe ".mode=" do
    it "does not raise an error when being set to :warn" do
      expect {
        TinyType.mode = :warn
      }.not_to raise_error
    end

    it "does not raise an error when being set to :raise" do
      expect {
        TinyType.mode = :raise
      }.not_to raise_error
    end

    it "raises an error when set to anything else" do
      expect {
        TinyType.mode = :booooo
      }.to raise_error("TinyType.mode must be one of [:raise, :warn]")
    end
  end

  describe ".mode" do
    it "returns the correct mode when set to :warn" do
      TinyType.mode = :warn
      expect(TinyType.mode).to eq(:warn)
    end

    it "returns the correct mode when set to :raise" do
      TinyType.mode = :raise
      expect(TinyType.mode).to eq(:raise)
    end
  end

  describe ".notify" do
    context "when TinyType.mode is :raise and no override is given" do
      it "raises an error and does not call TinyType.logger.warn" do
        TinyType.mode = :raise
        allow(TinyType.logger).to receive(:warn)

        expect {
          TinyType.notify(mode_override: nil, exception_class: TinyType::IncorrectArgumentType, message: "test message")
        }.to raise_error(TinyType::IncorrectArgumentType)

        expect(TinyType.logger).not_to have_received(:warn)
      end
    end

    context "when TinyType.mode is :raise and mode_override is set to :warn" do
      it "it does not raise an error and calls TinyType.logger.warn" do
        TinyType.mode = :raise
        allow(TinyType.logger).to receive(:warn)

        expect {
          TinyType.notify(mode_override: :warn, exception_class: TinyType::IncorrectArgumentType, message: "test message")
        }.not_to raise_error

        expect(TinyType.logger).to have_received(:warn).with("TinyType::IncorrectArgumentType: test message")
      end
    end

    context "when TinyType.mode is :warn and no override is given" do
      it "does not raise an error and calls TinyType.logger.warn" do
        TinyType.mode = :warn
        allow(TinyType.logger).to receive(:warn)

        expect {
          TinyType.notify(mode_override: nil, exception_class: TinyType::IncorrectArgumentType, message: "test message")
        }.not_to raise_error

        expect(TinyType.logger).to have_received(:warn).with("TinyType::IncorrectArgumentType: test message")
      end
    end

    context "when TinyType.mode is :warn and mode_override is set to :raise" do
      it "does not raise an error and calls TinyType.logger.warn" do
        TinyType.mode = :warn
        allow(TinyType.logger).to receive(:warn)

        expect {
          TinyType.notify(mode_override: :raise, exception_class: TinyType::IncorrectArgumentType, message: "test message")
        }.to raise_error(TinyType::IncorrectArgumentType)

        expect(TinyType.logger).not_to have_received(:warn)
      end
    end

    context "when TinyType.mode is :warn and mode_override is set to an unexpected value" do
      it "does not raise an error and calls TinyType.logger.warn" do
        TinyType.mode = :warn

        expect {
          TinyType.notify(mode_override: :foo, exception_class: TinyType::IncorrectArgumentType, message: "test message")
        }.to raise_error("Unknown notification mode for TinyType, expected one of [:raise, :warn] but got :foo")
      end
    end
  end

  describe "#accepts" do
    it "is accessible in an instance method" do
      instance = TestClass.new

      def instance.test(param1)
        accepts { {param1: String} }
      end

      expect { instance.test("foo") }.not_to raise_error
    end
  end

  describe ".accepts" do
    before { allow(TinyType).to receive(:notify) }

    it "raises an error when given an invalid declaration" do
      def TestClass.test(param1, param2)
        accepts { "foo" }
      end

      expect { TestClass.test("foo", 1) }.to raise_error(/The `accepts` method expects a block that returns a hash/i)
    end

    it "raises an error when given an invalid type declaration" do
      def TestClass.test(param1)
        accepts { {param1: 1234} }
      end

      expect { TestClass.test("foo") }.to raise_error(/Invalid type declaration for: ':param1'/i)
    end

    it "allows using a class literal in the declaration" do
      def TestClass.test(param1)
        accepts { {param1: String} }
      end

      expect { TestClass.test("foo") }.not_to raise_error
    end

    it "allows using a block matcher in the declaration" do
      def TestClass.test(param1)
        accepts { {param1: ->(mode_override:, argument_name:, argument_value:) { argument_value.is_a?(String) }} }
      end

      expect { TestClass.test("foo") }.not_to raise_error
    end

    it "allows using an array in the declaration" do
      def TestClass.test(param1)
        accepts { {param1: [String, NilClass]} }
      end

      expect { TestClass.test("foo") }.not_to raise_error
    end

    it "does not call TinyType.notify when local variables match declarations" do
      def TestClass.test(param1, param2)
        accepts { {param1: String, param2: Integer} }
      end

      expect(TinyType).not_to have_received(:notify)
    end

    it "does not call TinyType.notify when local variables match any option of union declaration" do
      def TestClass.test(param1)
        accepts { {param1: [String, Integer]} }
      end

      TestClass.test("foo")
      TestClass.test(1)

      expect(TinyType).not_to have_received(:notify)
    end

    it "calls TinyType.notify if a variable is not declared" do
      def TestClass.test(param1, param2 = nil)
        accepts { {param1: String} }
      end

      TestClass.test("foo")

      expect(TinyType).to have_received(:notify).with(
        mode_override: nil,
        exception_class: TinyType::UndeclaredArgument,
        message: "Undeclared arguments: [:param2]"
      )
    end

    it "calls TinyType.notify when local variables do not match union declaration" do
      def TestClass.test(param1)
        accepts { {param1: [NilClass, Integer]} }
      end

      TestClass.test("foo")

      expect(TinyType).to have_received(:notify).with(
        mode_override: nil,
        message: "Expected argument ':param1' to be a '[NilClass, Integer]', but got 'String'"
      )
    end

    it "calls TinyType.notify when local variables do not match declaration" do
      def TestClass.test(param1, param2)
        accepts { {param1: NilClass, param2: NilClass} }
      end

      TestClass.test("foo", 1234)

      expect(TinyType).to have_received(:notify).with(
        mode_override: nil,
        message: "Expected argument ':param1' to be a 'NilClass', but got 'String'"
      )
      expect(TinyType).to have_received(:notify).with(
        mode_override: nil,
        message: "Expected argument ':param2' to be a 'NilClass', but got 'Integer'"
      )
    end
  end

  describe ".array_of" do
    it "returns a proc" do
      result = TestClass.array_of(String, NilClass)
      expect(result).to be_a(Proc)
    end

    describe "the returned proc" do
      before { allow(TinyType).to receive(:notify) }

      it "does not call TinyType.notify when given an array where all elements match a single allowed class" do
        TestClass
          .array_of(String)
          .call(mode_override: nil, argument_name: :foo, argument_value: ["abc", "def"])

        expect(TinyType).not_to have_received(:notify)
      end

      it "does not call TinyType.notify when given an array where all elements match a list of allowed class" do
        TestClass
          .array_of(String, NilClass, Integer)
          .call(mode_override: nil, argument_name: :foo, argument_value: ["abc", nil, nil, 1, 2, 4])

        expect(TinyType).not_to have_received(:notify)
      end

      it "calls TinyType.notify when given an array where not all elements match a single allowed class" do
        TestClass
          .array_of(String)
          .call(mode_override: nil, argument_name: :foo, argument_value: ["abc", :symbol, 1])

        expect(TinyType).to have_received(:notify).with(
          mode_override: nil,
          message: "Expected array passed as argument `:foo` to contain only `[String]`, but got `[String, Symbol, Integer]`"
        )
      end

      it "calls TinyType.notify when given an array where not all elements match a list of allowed class" do
        TestClass
          .array_of(String, NilClass)
          .call(mode_override: nil, argument_name: :foo, argument_value: ["abc", :symbol, 1, nil])

        expect(TinyType).to have_received(:notify).with(
          mode_override: nil,
          message: "Expected array passed as argument `:foo` to contain only `[String, NilClass]`, but got `[String, Symbol, Integer, NilClass]`"
        )
      end

      it "calls TinyType.notify when given something other than an Array" do
        TestClass
          .array_of(String, NilClass)
          .call(mode_override: nil, argument_name: :foo, argument_value: nil)

        expect(TinyType).to have_received(:notify).with(
          mode_override: nil,
          message: "Expected an Array to be passed as argument `:foo`, but got `nil`"
        )
      end
    end
  end

  describe ".hash_with" do
    it "returns a proc" do
      result = TestClass.hash_with(:foo, :bar)
      expect(result).to be_a(Proc)
    end

    describe "the returned proc" do
      before { allow(TinyType).to receive(:notify) }

      it "does not raise an error when given a hash with all the keys we expect" do
        TestClass
          .hash_with(:foo, :bar)
          .call(mode_override: nil, argument_name: :foo, argument_value: {foo: 1, bar: 2})

        expect(TinyType).not_to have_received(:notify)
      end

      it "does not call TinyType.notify when given a hash with extra keys" do
        TestClass
          .hash_with(:foo, :bar)
          .call(mode_override: nil, argument_name: :foo, argument_value: {foo: 1, bar: 2, baz: 3})

        expect(TinyType).not_to have_received(:notify)
      end

      it "calls TinyType.notify when given a hash with missing keys" do
        TestClass
          .hash_with(:foo, :bar)
          .call(mode_override: nil, argument_name: :foo, argument_value: {foo: 1})

        expect(TinyType).to have_received(:notify).with(
          mode_override: nil,
          message: "Expected hash passed as argument `:foo` to have key `:bar`, but it did not"
        )
      end

      it "calls TinyType.notify when given something other than a Hash" do
        TestClass
          .hash_with(:foo)
          .call(mode_override: nil, argument_name: :foo, argument_value: nil)

        expect(TinyType).to have_received(:notify).with(
          mode_override: nil,
          message: "Expected a Hash to be passed as argument `:foo`, but got `nil`"
        )
      end
    end
  end

  describe ".with_interface" do
    it "returns a proc" do
      result = TestClass.with_interface(:foo, :bar)
      expect(result).to be_a(Proc)
    end

    describe "the returned proc" do
      before { allow(TinyType).to receive(:notify) }

      it "does not call TinyType.notify when given an object that responds to the required methods" do
        TestClass
          .with_interface(:foo, :bar)
          .call(mode_override: nil, argument_name: :foo, argument_value: double(foo: 1, bar: 2))

        expect(TinyType).not_to have_received(:notify)
      end

      it "calls TinyType.notify when given an object that does not respond to the required methods" do
        TestClass
          .with_interface(:foo, :bar)
          .call(mode_override: nil, argument_name: :foo, argument_value: double(foo: 1))

        expect(TinyType).to have_received(:notify).with(
          mode_override: nil,
          message: "Expected object passed as argument `:foo` to respond to `.bar`, but it did not"
        )
      end
    end
  end
end
