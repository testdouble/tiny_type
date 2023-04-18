require "parser/current"

module TinyType
  module RSpecMatchers
    class SyntaxTreeWrapper
      def self.parse(string)
        ast = Parser::CurrentRuby.parse(string).to_sexp_array
        new(ast)
      end

      def initialize(ast)
        @ast = ast
      end

      def [](index)
        @ast[index]
      end

      def each(&block)
        @ast.each(&block)
      end

      def find(array_of_symbols, ast = nil)
        ast ||= @ast

        if array_of_symbols.map.with_index { |symbol, index| ast[index] == symbol }.all?
          ast
        else
          ast.each do |child|
            next if child.nil?
            next if child.is_a?(Symbol)
            next unless child.is_a?(Array)

            result = find(array_of_symbols, child)
            return SyntaxTreeWrapper.new(result) unless result.nil?
          end

          nil
        end
      end
    end

    class TinyTypeSingularMethodMatcher
      def initialize(method_name:, type:)
        @method_name = method_name.to_sym
        @type = type
        @failure_message = nil
        @klass = nil
      end

      def matches?(klass)
        @klass = klass

        begin
          method = @type == :instance ? klass.instance_method(@method_name) : klass.method(@method_name)
        rescue NameError
          @failure_message = "No #{@type} method `#{@method_name}` found on class `#{klass}`, did you spell the method name correctly?"
          return false
        end

        source_location, _line_no = method.source_location
        raise "Could not find source location for method `#{@method_name}`. TinyType's test helpers are not compatible with dynamically created methods." unless source_location

        source = File.read(source_location)
        ast = SyntaxTreeWrapper.parse(source)

        method_ast = ast.find([:def, @method_name]) || ast.find([:defs, [:self], @method_name])
        accepts_call = method_ast.find([:send, nil, :accepts])

        !accepts_call.nil?
      end

      def supports_block_expectations?
        false
      end

      def description
        "declare input types for `#{@method_name}` method"
      end

      def failure_message
        @failure_message || "Expected `#{@klass.name}#{@type == :instance ? "#" : "."}#{@method_name}` method to declare input types by using `accepts`, but it did not."
      end
    end

    class TinyTypeAllMethodsMatcher
      def initialize
        @failures = []
        @klass = nil
      end

      def matches?(klass)
        @klass = klass

        instance_methods = klass.instance_methods(false)
        class_methods = klass.methods(false)

        instance_methods.each do |method_name|
          matcher = TinyTypeSingularMethodMatcher.new(method_name: method_name, type: :instance)
          unless matcher.matches?(klass)
            @failures << matcher.failure_message
          end
        end

        class_methods.each do |method_name|
          matcher = TinyTypeSingularMethodMatcher.new(method_name: method_name, type: :class)
          unless matcher.matches?(klass)
            @failures << matcher.failure_message
          end
        end

        @failures.length == 0
      end

      def failure_message
        @failures.join("\n")
      end

      def description
        "declare input types for all methods on `#{@klass.name}`"
      end
    end

    def declare_input_types_for_initializer
      TinyTypeSingularMethodMatcher.new(method_name: :initialize, type: :instance)
    end

    def declare_input_types_for_instance_method(method_name)
      TinyTypeSingularMethodMatcher.new(method_name: method_name, type: :instance)
    end

    def declare_input_types_for_class_method(method_name)
      TinyTypeSingularMethodMatcher.new(method_name: method_name, type: :class)
    end

    def declare_input_types_for_all_methods
      TinyTypeAllMethodsMatcher.new
    end
  end
end
