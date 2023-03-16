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
        accepts { {param1: ->(_arg_name, x) { x.is_a?(String) }} }
      end

      expect { TestClass.test("foo") }.not_to raise_error
    end

    it "allows using an array in the declaration" do
      def TestClass.test(param1)
        accepts { {param1: [String, NilClass]} }
      end

      expect { TestClass.test("foo") }.not_to raise_error
    end

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

      expect { TestClass.test("foo") }.to raise_error(/Undeclared arguments: \[:param2\]/i)
    end

    it "raises an error when local variables do not match declaration" do
      def TestClass.test(param1, param2)
        accepts { {param1: NilClass, param2: NilClass} }
      end

      expect { TestClass.test("foo", 1234) }.to raise_error(MiniType::IncorrectParameterType)
    end
  end
end
