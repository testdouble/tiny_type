# frozen_string_literal: true

require_relative "mini_type/version"
require "logger"

module MiniType
  class MiniTypeError < StandardError; end

  class IncorrectArgumentType < MiniTypeError; end

  class UndeclaredArgument < MiniTypeError; end

  VALID_MODES = [:raise, :warn]

  INCORRECT_ARGUMENT_TYPE = "Expected argument ':%s' to be of type '%s', but got '%s'"
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

  @mode = :raise
  @logger = Logger.new($stderr)

  def self.mode=(mode)
    raise "MiniType.mode must be one of #{VALID_MODES.inspect}" unless VALID_MODES.include?(mode)
    @mode = mode
  end

  def self.mode
    @mode
  end

  def self.logger=(logger)
    raise "MiniType.logger expects an object that responds to :warn" unless logger.respond_to?(:warn)
    @logger = logger
  end

  def self.logger
    @logger
  end

  def self.notify(mode_override:, message:, exception_class: IncorrectArgumentType)
    mode_override ||= mode

    if mode_override == :raise
      raise(exception_class, message)
    elsif mode_override == :warn
      logger.warn("#{exception_class.name}: #{message}")
    else
      raise "Unknown notification mode for MiniType, expected one of #{VALID_MODES.inspect} but got #{mode_override.inspect}"
    end
  end

  module Methods
    def accepts(mode_override = nil, &block)
      declaration = block.call
      context = block.binding

      raise(IncorrectArgumentType, INVALID_DECLARAION % [declaration.inspect]) unless declaration.is_a?(Hash)

      undeclared_arguments = context.local_variables - declaration.keys
      unless undeclared_arguments.empty?
        MiniType.notify(
          mode_override: mode_override,
          exception_class: UndeclaredArgument,
          message: "Undeclared arguments: #{undeclared_arguments.inspect}"
        )
      end

      declaration.each_pair do |argument_name, allowable_type|
        argument_value = context.local_variable_get(argument_name)

        if allowable_type.respond_to?(:call)
          allowable_type.call(mode_override: mode_override, argument_name: argument_name, argument_value: argument_value)
        elsif allowable_type.is_a?(Array)
          next if allowable_type.include?(argument_value.class)
          MiniType.notify(mode_override: mode_override, message: "Expected argument ':#{argument_name}' to be a '#{allowable_type}', but got '#{argument_value.class.name}'")
        elsif allowable_type.is_a?(Class)
          next if argument_value.is_a?(allowable_type)
          MiniType.notify(mode_override: mode_override, message: "Expected argument ':#{argument_name}' to be a '#{allowable_type}', but got '#{argument_value.class.name}'")
        else
          raise(IncorrectArgumentType, INVALID_TYPE % [argument_name])
        end
      end
    end

    def array_of(*allowed_classes)
      ->(mode_override:, argument_name:, argument_value:) {
        unless argument_value.is_a?(Array)
          return MiniType.notify(
            mode_override: mode_override,
            message: "Expected an Array to be passed as argument `:#{argument_name}`, but got `#{argument_value.inspect}`"
          )
        end

        actual_classes = argument_value.map(&:class).uniq
        return if actual_classes.map(&:name).sort == allowed_classes.map(&:name).sort

        MiniType.notify(
          mode_override: mode_override,
          message: "Expected array passed as argument `:#{argument_name}` to contain only `#{allowed_classes}`, but got `#{actual_classes}`"
        )
      }
    end

    def hash_with(*expected_keys)
      ->(mode_override:, argument_name:, argument_value:) {
        unless argument_value.is_a?(Hash)
          return MiniType.notify(
            mode_override: nil,
            message: "Expected a Hash to be passed as argument `:#{argument_name}`, but got `#{argument_value.inspect}`"
          )
        end

        expected_keys.each do |key|
          next if argument_value.has_key?(key)

          MiniType.notify(
            mode_override: mode_override,
            message: "Expected hash passed as argument `:#{argument_name}` to have key `#{key.inspect}`, but it did not"
          )
        end
      }
    end

    def with_interface(*must_respond_to)
      ->(mode_override:, argument_name:, argument_value:) {
        must_respond_to.each do |method_name|
          next if argument_value.respond_to?(method_name)

          MiniType.notify(
            mode_override: mode_override,
            message: "Expected object passed as argument `:#{argument_name}` to respond to `.#{method_name}`, but it did not"
          )
        end
      }
    end
  end
end
