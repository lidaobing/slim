module Slim
  # For logic-less mode, objects can be encased in the Wrapper class.
  #
  # For Rails, this allows us to use the environment provided for rendering
  # a view including the instance variables, view helper and application helper
  # methods.
  class Wrapper
    attr_reader :value, :parent

    def initialize(value, parent = nil)
      @value, @parent = value, parent
    end

    # To find the reference, first check for standard method
    # access by using respond_to?.
    #
    # If not found, check to see if the value is a hash and if the
    # the name is a key on the hash.
    #
    # Not a hash, or not a key on the hash, then check to see if there
    # is an instance variable with the name.
    #
    # If the instance variable doesn't exist and there is a parent object,
    # go through the same steps on the parent object.  This is useful when
    # you are iterating over objects.
    def [](name)
      if value.respond_to?(name)
        wrap value.send(name)
      elsif value.respond_to?(:[])
        wrap value[name]
      elsif value.instance_variable_defined?("@#{name}")
        wrap value.instance_variable_get("@#{name}")
      elsif parent
        parent[name]
      end
    end

    # Empty objects must appear empty for inverted sections
    def empty?
      value.respond_to?(:empty) && value.empty?
    end

    # Used for output
    def to_s
      value.to_s
    end

    private

    def wrap(value)
      # Primitives are not wrapped
      if [String, Numeric, TrueClass, FalseClass, NilClass].any? {|primitive| primitive === value }
        value
      # Enumerables are mapped with wrapped values (except Hash-like objects)
      elsif !value.respond_to?(:has_key?) && value.respond_to?(:map)
        value.map {|v| wrap(v) }
      else
        Wrapper.new(value, self)
      end
    end
  end
end