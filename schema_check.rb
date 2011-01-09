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
    name = name.to_s
    if /\!$/ =~ name
      name.chop!
      @params[name].tap{|x| raise "#{name} is not defined" unless x}
    elsif /\?$/ =~ name
      name.chop!
      @params.has_key?(name)
    else
      @params[name]
    end
  end
end

def schema_check( object, kind, schema = {})
  case kind
  when IsDefinition["string"]
    raise "not a string" unless object.is_a? String
  when IsDefinition["number"]
    raise "not a number" unless object.is_a? Numeric
  when IsDefinition["range"]
    raise "not a number" unless object.is_a? Numeric
    bottom, top = Kind[kind].limits!
    raise "value out of range" unless (bottom..top).include?(object)
  when IsDefinition["array"]
    raise "not an array" unless object.is_a? Array
    object.each do |entry|
      if Kind[kind].contents?
        schema_check( entry, Kind[kind].contents, schema )
      end
    end
  else
    raise "Invalid definition #{kind.inspect}"
  end
end

