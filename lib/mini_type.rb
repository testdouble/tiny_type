# frozen_string_literal: true

require_relative "mini_type/version"

module MiniType
  class MiniTypeError < StandardError; end

  class IncorrectParameterType < MiniTypeError; end

  INCORRECT_PARAMETER_TYPE = "Expected parameter ':%s' to be of type '%s', but got '%s'"

  def self.included(base)
    base.extend(Methods)
    base.include(Methods)
  end

  module Methods
    def accepts(&block)
      arguments = block.call
      context = block.binding

      context.local_variables.each do |local_variable_name|
        unless arguments.key?(local_variable_name)
          raise ArgumentError.new("Undeclared argument: '#{local_variable_name}'")
        end
      end

      arguments.each_pair do |argument_name, argument_types|
        argument_value = context.local_variable_get(argument_name)

        unless [argument_types].flatten.include?(argument_value.class)
          raise(IncorrectParameterType, INCORRECT_PARAMETER_TYPE % [argument_name, argument_types, argument_value.class.name])
        end
      end
    end
  end
end
