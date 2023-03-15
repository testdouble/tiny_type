# frozen_string_literal: true

include MiniType

RSpec.describe MiniType do
  describe "VERSION" do
    it "has a version number" do
      expect(MiniType::VERSION).not_to be nil
    end
  end

  describe "#accepts" do
    it "does not raise an error when local variables match declaratios" do
      expect {
        param1 = "foo"
        param2 = 1234

        accepts { {param1: String, param2: Integer} }
      }.not_to raise_error
    end

    it "does not raise an error when local variables match first option of union declaration" do
      expect {
        param1 = "foo"

        accepts { {param1: [String, Integer]} }
      }.not_to raise_error
    end

    it "does not raise an error when local variables match second option of union declaration" do
      expect {
        param1 = 1

        accepts { {param1: [String, Integer]} }
      }.not_to raise_error
    end

    it "raises an error if a variable is not declared" do
      expect {
        param1 = "foo"
        param2 = 1234

        accepts { {param1: String} }
      }.to raise_error(/Undeclared argument: 'param2'/i)
    end

    it "raises an error when local variables do not match declaration" do
      expect {
        param1 = "foo"
        param2 = 1234

        accepts { {param1: NilClass, param2: NilClass} }
      }.to raise_error(IncorrectParameterType)
    end
  end
end
