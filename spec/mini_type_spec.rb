# frozen_string_literal: true

class TestClass
  include MiniType
end

RSpec.describe MiniType do
  describe "VERSION" do
    it "has a version number" do
      expect(MiniType::VERSION).not_to be nil
    end
  end

  describe "#accepts" do
    it "works correctly in an instance method" do
      instance = TestClass.new

      def instance.test(param1)
        accepts { {param1: String} }
      end

      expect { instance.test("foo") }.not_to raise_error
    end
  end

  describe ".accepts" do
    it "does not raise an error when local variables match declarations" do
      def TestClass.test(param1, param2)
        accepts { {param1: String, param2: Integer} }
      end

      expect { TestClass.test("foo", 1) }.not_to raise_error
    end

    it "does not raise an error when local variables match any option of union declaration" do
      def TestClass.test(param1)
        accepts { {param1: [String, Integer]} }
      end

      expect { TestClass.test("foo") }.not_to raise_error
      expect { TestClass.test(1) }.not_to raise_error
    end

    it "raises an error if a variable is not declared" do
      def TestClass.test(param1, param2 = nil)
        accepts { {param1: String} }
      end

      expect { TestClass.test("foo") }.to raise_error(/Undeclared argument: 'param2'/i)
    end

    it "raises an error when local variables do not match declaration" do
      def TestClass.test(param1, param2)
        accepts { {param1: NilClass, param2: NilClass} }
      end

      expect { TestClass.test("foo", 1234) }.to raise_error(MiniType::IncorrectParameterType)
    end
  end
end
