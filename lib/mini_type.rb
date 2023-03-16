# frozen_string_literal: true

require_relative "mini_type/version"

module MiniType
  class MiniTypeError < StandardError; end

  class IncorrectParameterType < MiniTypeError; end

  INCORRECT_PARAMETER_TYPE = "Expected parameter ':%s' to be of type '%s', but got '%s'"
  INVALID_DECLARAION = "Invalid type declaration. The `accepts` method expects a block that returns a hash, like: `accepts {{ foo: String }}`. Received: '%s'"
  INVALID_TYPE = "Invalid type declaration for: ':%s'. Type declaration should be a class literal (`String`), an aray of class literals (`[String, NilClass]`), or a matcher (`array_of(String)`)."

  def self.included(base)
    base.extend(Methods)
    base.include(Methods)
  end

  module Methods
    def accepts(&block)
      declaration = block.call
      context = block.binding

      raise(IncorrectParameterType, INVALID_DECLARAION % [declaration.inspect]) unless declaration.is_a?(Hash)

      undeclared_arguments = context.local_variables - declaration.keys
      raise ArgumentError.new("Undeclared arguments: #{undeclared_arguments.inspect}") unless undeclared_arguments.empty?

      declaration.each_pair do |argument_name, allowable_type|
        argument_value = context.local_variable_get(argument_name)

        if allowable_type.respond_to?(:call)
          allowable_type.call(argument_name, argument_value)
        elsif allowable_type.is_a?(Array)
          raise(IncorrectParameterType, INCORRECT_PARAMETER_TYPE % [argument_name, allowable_type, argument_value.class.name]) unless allowable_type.include?(argument_value.class)
        elsif allowable_type.is_a?(Class)
          raise(IncorrectParameterType, INCORRECT_PARAMETER_TYPE % [argument_name, allowable_type, argument_value.class.name]) unless argument_value.is_a?(allowable_type)
        else
          raise(IncorrectParameterType, INVALID_TYPE % [argument_name])
        end
      end
    end
  end
end
