# frozen_string_literal: true

# Test all the examples from the README to make sure everything works as expected.

class Rails
  def self.logger
    Logger.new($stdout)
  end
end

require "tiny_type"
class AmazingClass
  include TinyType

  def initialize(param1, param2 = nil)
    accepts { {param1: String, param2: [Integer, NilClass]} }
  end

  def print_name(name:)
    accepts { {name: String} }
  end

  def self.output_array(array)
    accepts { {array: array_of(String, NilClass)} }
  end

  def self.output_hash(hash)
    accepts { {hash: hash_with(:key1, :some_other_key)} }
  end

  def self.render(thing)
    accepts { {thing: with_interface(:render, :foo)} }
  end

  def self.safe_render(other_thing)
    accepts(:warn) { {other_thing: String} }
  end
end

RSpec.describe "TinyType Integration" do
  describe AmazingClass do
    it { expect(AmazingClass).to declare_input_types_for_instance_method(:print_name) }
    it { expect(AmazingClass).to declare_input_types_for_class_method(:output_array) }

    describe ".new" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.new("foo")
        }.not_to raise_error
      end

      it "raises IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.new(1)
        }.to raise_error(TinyType::IncorrectArgumentType)
      end
    end

    describe "#print_name" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.new("foo").print_name(name: "foo")
        }.not_to raise_error
      end

      it "raises TinyType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.new("foo").print_name(name: :incorrect)
        }.to raise_error(TinyType::IncorrectArgumentType)
      end
    end

    describe ".output_array" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.output_array(["foo", "bar", nil])
        }.not_to raise_error
      end

      it "raises TinyType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.output_array([:foo, 1])
        }.to raise_error(TinyType::IncorrectArgumentType)
      end
    end

    describe ".output_hash" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.output_hash({key1: 1, some_other_key: 2})
        }.not_to raise_error
      end

      it "raises TinyType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.output_hash({key1: 1, incorrect_key: 2})
        }.to raise_error(TinyType::IncorrectArgumentType)
      end
    end

    describe ".render" do
      it "does not raise any errors when given correct arguments" do
        expect {
          AmazingClass.render(double(render: "string", foo: "string"))
        }.not_to raise_error
      end

      it "raises TinyType::IncorrectArgumentType when given incorrect arguments" do
        expect {
          AmazingClass.render(double(render: "string", incorrect_method: 1))
        }.to raise_error(TinyType::IncorrectArgumentType)
      end
    end

    describe ".safe_render" do
      before { allow(TinyType.logger).to receive(:warn) }

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

        expect(TinyType.logger).to have_received(:warn).with(
          "TinyType::IncorrectArgumentType: Expected argument ':other_thing' to be a 'String', but got 'Integer'"
        )
      end
    end
  end
end
