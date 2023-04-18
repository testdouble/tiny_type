# frozen_string_literal: true

require "tiny_type"

class AllMethodsHaveTypes
  def initialize(param1)
    accepts { {param1: String} }
  end

  def instance_method_takes_string(name:)
    accepts { {name: String} }
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

RSpec.describe AllMethodsHaveTypes do
  it { expect(AllMethodsHaveTypes).to declare_input_types_for_all_methods }
end
