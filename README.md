[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![build](https://github.com/testdouble/tiny_type/actions/workflows/main.yml/badge.svg)](https://github.com/testdouble/tiny_type/actions/workflows/main.yml)
[![license](https://img.shields.io/github/license/testdouble/tiny_type)](https://github.com/testdouble/tiny_type/blob/main/LICENSE.txt)

# TinyType

TinyType is a small type guarding system for Ruby. TinyType does not require any setup other than installing the gem, and adding `accepts` definitions to your methods.

## Quick Start

```ruby
require "tiny_type"

class AmazingClass
  include TinyType

  def initialize(param1, param2 = nil)
    accepts {{ param1: String, param2: [Integer, NilClass] }}
  end

  def print_name(name:)
    accepts {{ name: String }}
  end

  def self.output_array(array)
    accepts {{ array: array_of(String, NilClass) }}
  end

  def self.output_hash(hash)
    accepts {{ hash: hash_with(:key1, :some_other_key) }}
  end

  def self.render(thing)
    accepts {{ thing: with_interface(:render, :foo) }}
  end

  def self.safe_render(other_thing)
    accepts(:warn) {{ other_thing: String }}
  end
end

```

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add tiny_type

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install tiny_type

## Why?

Having worked in both typed and untyped langauges I find myself loving the flexibility and clarity of Ruby, but missing the guidance that typing gives you when trying to understand a large or complex codebase. TinyType is designed to help document how methods are expected to be used, as well as providing an easy way to provide runtime guarding against unexpected input. For example, given this method:

```ruby
def add_one(input)
  input += 1
end
```

it is easy to imagine giving this method unexpected input like a `String` or other objects. Additionally in more complex examples it might be hard to work out what the expected input actually is, for example:

```ruby
def render(input)
  puts input.render_to_string
end
```

TinyType makes it easy to document and enforce expectations in your code:

```ruby
def render(input)
  accepts {{ input: RenderableObject }}
  puts input.render_to_string
end
```

now anyone working with this code can see at a glance what type of object it's expecting to be given, and if the `render` method is given anything other than a `RenderableObject` it will raise an exception with a clear error message:

```
Expected argument ':input' to be of type 'RenderableObject', but got 'String'
```

## Configuration:

```ruby
# raise an exception whenever arguments do not match declarations
TinyType.mode = :raise

# log a warning whenever arguments do not match declarations
TinyType.mode = :warn

# customize where TinyType warnings are logged
# accepts any object that reponds to :warn
TinyType.logger = Rails.logger
TinyType.logger = Logger.new($stderr)
TinyType.logger = Log4r::Logger.new("Application Log")
```

## Type declarations:

```ruby
# accept an object of a given class
accepts {{ arg1: String }}

# accept an object that is one of a list of classes
accepts {{ arg1: [String, OtherClass, ThirdClass] }}

# accept an array filled with a specific class
accepts {{ arg1: array_of(String) }}

# accept an array filled with any of a list of classes
accepts {{ arg1: array_of(String, OtherClass, ThirdClass) }}

# accept a hash that must have the specified keys
accepts {{ arg1: hash_with(:foo, :bar) }}

# accept an object that must respond to the specified methods
accepts {{ arg1: with_interface(:method1, :method2) }}

# log a warning when this declaration is not met
# setting :warn here overrides the global config
accepts(:warn) {{ arg1: String }}

# raise an exception when this declaration is not met
# setting :raise here overrides the global config
accepts(:raise) {{ arg1: String }}
```

## Testing

Because the TinyType API is declarative, and the type matchers themselves are tested as part of the TinyType project, there's no real need to test your type declarations. Instead it's better practice to simply assert that a particular method uses TinyType to define/guard its inputs. TinyType provides custom RSpec matchers to make this easy:

```ruby
RSpec.describe Foo do
  # assert that the initializer for a class declares input types
  it { expect(described_class).to declare_input_types_for_initializer }

  # assert that an instance method declares input types
  it { expect(described_class).to declare_input_types_for_instance_method(:instance_method_foo) }

  # assert that a class method declares input types
  it { expect(described_class).to declare_input_types_for_class_method(:class_method_foo) }

  # assert that ALL methods within a class declare input types
  # if you want to make sure that an entire class uses TinyType
  # this is the simplest way
  it { expect(described_class).to declare_input_types_for_all_methods }
end
```

To enable TinyType's custom matchers in your project, simply include them in your RSpec configuration like so:

```ruby
RSpec.configure do |config|
  # add this line
  config.include TinyType::RSpecMatchers
end
```

## How it works

The `accepts` method takes a mode and a block as its arguments, the block should return a hash containing the local variables you want to check. This can be expressed in two ways:

```ruby
accepts(:raise) do
  { foo: String }
end

# or the preferred style:
accepts(:raise) {{ foo: String }}
```

In Ruby blocks capture information about the context in which they were defined. This allows us to inspect variables that were local to the block when it was defined like so:

```ruby
def accepts(mode, &block)
  context = block.binding
  context.local_variables.each do |name|
    puts "Name: #{name}"
    puts "Value: #{context.local_variable_get(name).inspect}"
  end
end

foo = 1
bar = "abc"

accepts {{ }} # block that returns empty hash

# Output:
# => Name: bar
# => Value: "abc"
# => Name: foo
# => Value: 1
```

The nice thing about this is it allows `TinyType` to be implemented in a really simple way with no 'magic'! 🎉

## Quirks and features

The `accepts` method inspects *all* local variables at the point at which it's invoked, it is not limited to being used at the top of a method declaration:

```ruby
include TinyType

foo = :foo
bar = :bar

accepts {{ foo: String }}

#=> Undeclared arguments: [:bar, :_]
```

TinyType is not really intended to be used this way, but perhaps using it this way has some value that I haven't thought of yet? Submit a PR with documentation changes if you use TinyType in a new and interesting way!

## Downsides

The only downside to using TinyType is that it does add a small amount of overhead to each method call that uses it to declare input types. This overhead is very small and you won't notice it when used alongside a method body that does any amount of 'real work', but you may find it unacceptable in a code-path that is frequently called and otherwise very light-wight. There are profiling and benchmarking operations that run as part of TinyType's test suite, and PRs that improve performance are welcome! 

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testdouble/tiny_type. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testdouble/tiny_type/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TinyType project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testdouble/tiny_type/blob/main/CODE_OF_CONDUCT.md).
