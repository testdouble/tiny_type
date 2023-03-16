# frozen_string_literal: true

# Test all the examples from the README to make sure everything works as expected.

class AmazingClass
  # include MiniType in your class
  include MiniType

  def initialize(param1, param2 = nil)
    # param1 should only be a String
    # param2 can be a String or `nil`
    accepts { {param1: String, param2: [Integer, NilClass]} }

    # do some work
  end

  def print_name(name:)
    # works with positional arguments and with keyword arguments
    accepts { {name: String} }

    # do some other work
  end

  def self.output_array(array)
    # allow an array filled with defined types of objects
    accepts { {array: array_of(String, NilClass)} }

    # keep working
  end

  def self.output_hash(hash)
    # define that a parameter is a hash that should have certain keys
    accepts { {hash: hash_with(:key1, :some_other_key)} }

    # use the hash
  end

  def self.render(thing)
    # define that a parameter must respond to a given interface
    accepts { {thing: with_interface(:render, :foo)} }

    # use the interface
  end
end

RSpec.describe "MiniType Integration" do
  describe "AmazingClass" do
    describe ".new" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.new("foo")
        }.not_to raise_error
      end

      it "raises IncorrectParameterType when given incorrect arguments" do
        expect {
          AmazingClass.new(1)
        }.to raise_error(MiniType::IncorrectParameterType)
      end
    end

    describe "#print_name" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.new("foo").print_name(name: "foo")
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectParameterType when given incorrect arguments" do
        expect {
          AmazingClass.new("foo").print_name(name: :incorrect)
        }.to raise_error(MiniType::IncorrectParameterType)
      end
    end

    describe ".output_array" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.output_array(["foo", "bar", nil])
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectParameterType when given incorrect arguments" do
        expect {
          AmazingClass.output_array([:foo, 1])
        }.to raise_error(MiniType::IncorrectParameterType)
      end
    end

    describe ".output_hash" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.output_hash({key1: 1, some_other_key: 2})
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectParameterType when given incorrect arguments" do
        expect {
          AmazingClass.output_hash({key1: 1, incorrect_key: 2})
        }.to raise_error(MiniType::IncorrectParameterType)
      end
    end

    describe ".render" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.render(double(render: "string", foo: "string"))
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectParameterType when given incorrect arguments" do
        expect {
          AmazingClass.render(double(render: "string", incorrect_method: 1))
        }.to raise_error(MiniType::IncorrectParameterType)
      end
    end
  end
end