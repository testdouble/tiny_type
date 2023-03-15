[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![build](https://github.com/testdouble/mini_type/actions/workflows/main.yml/badge.svg)](https://github.com/testdouble/mini_type/actions/workflows/main.yml)
![license](https://img.shields.io/github/license/testdouble/mini_type)

# MiniType

MiniType is a small runtime type checking system for Ruby! MiniType does not require any setup other than installing the gem, and adding `accepts` definitions for your methods.

## Usage

MiniType is designed to help document how methods are expected to be used, as well as providing an easy way to provide runtime guarding against unexpected input. For example, given this method:

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

MiniType makes it easy to document and enforce expectations in your code:

```ruby
def render(input)
  accepts {{ input: RenderableObject }}
  puts input.render_to_string
end
```

now anyone working with this code can see at a glance what type of object it's expecting to be given, and if the `render` method is given anything other than a `RenderableObject` it will raise an exception with a clear error message:

```
Expected parameter ':input' to be of type 'RenderableObject', but got 'String'
```

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add mini_type

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install mini_type


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/testdouble/mini_type. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/testdouble/mini_type/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MiniType project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/testdouble/mini_type/blob/main/CODE_OF_CONDUCT.md).
