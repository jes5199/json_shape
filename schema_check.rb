class IsDefinition
  def self.[](name)
    self.new(name)
  end
  def initialize(name)
    @name = name
  end

  def ===(val)
    return true if val == @name
    return true if val.first == @name
  end
end

class Kind
  def self.[](name)
    self.new(name)
  end

  def initialize(kind)
    @name, @params = kind
    @params ||= {}
  end

  def method_missing(name, *args)
    @params[name.to_s].tap{|x| raise "#{name} is not defined" unless x}
  end
end

def schema_check( object, kind, schema = {})
  case kind
  when IsDefinition["string"]
    raise "not a string" unless object.is_a? String
  when IsDefinition["range"]
    raise "not a number" unless object.is_a? Numeric
    bottom, top = Kind[kind].limits
    raise "value out of range" unless (bottom..top).include?(object)
  else
    raise "Invalid definition #{kind.inspect}"
  end
end

