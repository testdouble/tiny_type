# frozen_string_literal: true

require_relative "mini_type/version"

module MiniType
  class MiniTypeError < StandardError; end

  class IncorrectArgumentType < MiniTypeError; end

  INCORRECT_PARAMETER_TYPE = "Expected argument ':%s' to be of type '%s', but got '%s'"
  INVALID_DECLARAION = "Invalid type declaration. The `accepts` method expects a block that returns a hash, like: `accepts {{ foo: String }}`. Received: '%s'"
  INVALID_TYPE = "Invalid type declaration for: ':%s'. Type declaration should be a class literal (`String`), an aray of class literals (`[String, NilClass]`), or a matcher (`array_of(String)`)."

  ARRAY_OF_NOT_GIVEN_ARRAY = "Expected an Array to be passed as argument `:%s`, but got `%s`"
  ARRAY_OF_INVALID_CONTENT = "Expected array passed as argument `:%s` to contain only `%s`, but got `%s`"

  HASH_WITH_NOT_GIVEN_HASH = "Expected a Hash to be passed as argument `:%s`, but got `%s`"
  HASH_WITH_INVALID_CONTENT = "Expected hash passed as argument `:%s` to have key `%s`, but it did not`"

  WITH_INTERFACE_DOESNT_RESPOND = "Expected object passed as argument `:%s` to respond to `.%s`, but it did not"

  def self.included(base)
    base.extend(Methods)
    base.include(Methods)
  end

  module Methods
    def accepts(&block)
      declaration = block.call
      context = block.binding

      raise(IncorrectArgumentType, INVALID_DECLARAION % [declaration.inspect]) unless declaration.is_a?(Hash)

      undeclared_arguments = context.local_variables - declaration.keys
      raise ArgumentError.new("Undeclared arguments: #{undeclared_arguments.inspect}") unless undeclared_arguments.empty?

      declaration.each_pair do |argument_name, allowable_type|
        argument_value = context.local_variable_get(argument_name)

        if allowable_type.respond_to?(:call)
          allowable_type.call(argument_name, argument_value)
        elsif allowable_type.is_a?(Array)
          raise(IncorrectArgumentType, INCORRECT_PARAMETER_TYPE % [argument_name, allowable_type, argument_value.class.name]) unless allowable_type.include?(argument_value.class)
        elsif allowable_type.is_a?(Class)
          raise(IncorrectArgumentType, INCORRECT_PARAMETER_TYPE % [argument_name, allowable_type, argument_value.class.name]) unless argument_value.is_a?(allowable_type)
        else
          raise(IncorrectArgumentType, INVALID_TYPE % [argument_name])
        end
      end
    end

    def array_of(*allowed_classes)
      ->(argument_name, argument_value) {
        raise(IncorrectArgumentType, ARRAY_OF_NOT_GIVEN_ARRAY % [argument_name, argument_value.inspect]) unless argument_value.is_a?(Array)

        actual_classes = argument_value.map(&:class).uniq
        raise(IncorrectArgumentType, ARRAY_OF_INVALID_CONTENT % [argument_name, allowed_classes, actual_classes]) unless actual_classes.map(&:name).sort == allowed_classes.map(&:name).sort
      }
    end

    def hash_with(*expected_keys)
      ->(argument_name, argument_value) {
        raise(IncorrectArgumentType, HASH_WITH_NOT_GIVEN_HASH % [argument_name, argument_value.inspect]) unless argument_value.is_a?(Hash)

        expected_keys.each do |key|
          raise(IncorrectArgumentType, HASH_WITH_INVALID_CONTENT % [argument_name, key.inspect]) unless argument_value.has_key?(key)
        end
      }
    end

    def with_interface(*must_respond_to)
      ->(argument_name, argument_value) {
        must_respond_to.each do |method_name|
          raise(IncorrectArgumentType, WITH_INTERFACE_DOESNT_RESPOND % [argument_name, method_name]) unless argument_value.respond_to?(method_name)
        end
      }
    end
  end
end
