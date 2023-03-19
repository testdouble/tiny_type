# frozen_string_literal: true

# Test all the examples from the README to make sure everything works as expected.

class Rails
  def self.logger
    Logger.new($stdout)
  end
end

require "mini_type"

MiniType.mode = :raise # set to :raise or :warn
MiniType.logger = Rails.logger # when using :warn set the logger to your application's logger

class AmazingClass
  # include MiniType in your class
  include MiniType

  def initialize(param1, param2 = nil)
    accepts { {param1: String, param2: [Integer, NilClass]} }
    # param1 should only be a String
    # param2 can be a Integer or `nil`
  end

  def print_name(name:)
    accepts { {name: String} }
    # works with positional arguments and with keyword arguments
  end

  def self.output_array(array)
    accepts { {array: array_of(String, NilClass)} }
    # allow an array filled with defined types of objects
  end

  def self.output_hash(hash)
    accepts { {hash: hash_with(:key1, :some_other_key)} }
    # define that a argument is a hash that should have certain keys
  end

  def self.render(thing)
    accepts { {thing: with_interface(:render, :foo)} }
    # define that an argument must respond to a given interface
  end

  def self.safe_render(thing)
    accepts(:warn) { {thing: String} }
    # log a warning rather than raising an error for this method
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

      it "raises IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.new(1)
        }.to raise_error(MiniType::IncorrectArgumentType)
      end
    end

    describe "#print_name" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.new("foo").print_name(name: "foo")
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.new("foo").print_name(name: :incorrect)
        }.to raise_error(MiniType::IncorrectArgumentType)
      end
    end

    describe ".output_array" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.output_array(["foo", "bar", nil])
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.output_array([:foo, 1])
        }.to raise_error(MiniType::IncorrectArgumentType)
      end
    end

    describe ".output_hash" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.output_hash({key1: 1, some_other_key: 2})
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.output_hash({key1: 1, incorrect_key: 2})
        }.to raise_error(MiniType::IncorrectArgumentType)
      end
    end

    describe ".render" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.render(double(render: "string", foo: "string"))
        }.not_to raise_error
      end

      it "raises MiniType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.render(double(render: "string", incorrect_method: 1))
        }.to raise_error(MiniType::IncorrectArgumentType)
      end
    end

    describe ".safe_render" do
      before { allow(MiniType.logger).to receive(:warn) }

      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.safe_render("foo")
        }.not_to raise_error
      end

      it "does not raise any errors when given incorrect arguments" do
        expect {
          AmazingClass.safe_render(123)
        }.not_to raise_error
      end

      it "logs a warning when given incorrect arguments" do
        AmazingClass.safe_render(123)

        expect(MiniType.logger).to have_received(:warn).with(
          "MiniType::IncorrectArgumentType: Expected argument ':thing' to be a 'String', but got 'Integer'"
        )
      end
    end
  end
end
