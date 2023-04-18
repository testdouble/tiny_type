# frozen_string_literal: true

require "tiny_type"

class DifficultMatcherTestClass
  include TinyType

  def initialize(param1)
    accepts { {param1: String} }
  end

  def instance_method_takes_anything(name:)
    # accepts { {name: String} }
  end

  def self.class_method_takes_array(array)
    accepts { {array: array_of(String, NilClass)} }
  end

  class << self
    def class_method_takes_block(&block)
      accepts { {block: Proc} }
    end
  end
end

RSpec.describe DifficultMatcherTestClass do
  it { expect(described_class).to declare_input_types_for_initializer }
  it { expect(described_class).not_to declare_input_types_for_instance_method(:instance_method_takes_anything) }
  it { expect(described_class).to declare_input_types_for_class_method(:class_method_takes_array) }
  it { expect(described_class).to declare_input_types_for_class_method(:class_method_takes_block) }
end
