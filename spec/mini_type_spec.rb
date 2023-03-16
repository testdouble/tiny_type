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

  describe ".array_of" do
    it "returns a proc" do
      result = TestClass.array_of(String, NilClass)
      expect(result).to be_a(Proc)
    end

    describe "the returned proc" do
      it "does not raise an error when given an array where all elements match a single allowed class" do
        proc = TestClass.array_of(String)

        expect {
          proc.call(:foo, ["abc", "def"])
        }.not_to raise_error
      end

      it "does not raise an error when given an array where all elements match a list of allowed class" do
        proc = TestClass.array_of(String, NilClass, Integer)

        expect {
          proc.call(:foo, ["abc", nil, nil, 1, 2, 4])
        }.not_to raise_error
      end

      it "raises an error when given an array where not all elements match a single allowed class" do
        proc = TestClass.array_of(String)

        expect {
          proc.call(:foo, ["abc", :symbol, 1])
        }.to raise_error(/Expected array passed as parameter `:foo` to contain only `\[String\]`, but got `\[String, Symbol, Integer\]`/i)
      end

      it "raises an error when given an array where not all elements match a list of allowed class" do
        proc = TestClass.array_of(String, NilClass)

        expect {
          proc.call(:foo, ["abc", :symbol, 1, nil])
        }.to raise_error(/Expected array passed as parameter `:foo` to contain only `\[String, NilClass\]`, but got `\[String, Symbol, Integer, NilClass\]`/i)
      end

      it "raises an error when given something other than an Array" do
        proc = TestClass.array_of(String, NilClass)

        expect {
          proc.call(:foo, nil)
        }.to raise_error(/Expected an array to be passed as parameter `:foo`, but got `nil`/i)
      end
    end
  end
end
