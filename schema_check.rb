class IsDefinition
  attr :name, :params

  def self.[](name)
    self.new(name)
  end
  def initialize(name)
    @name = name
  end

  def ===(val)
    return true if val.name == @name
  end

end

class Kind
  attr :name, :params

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
  kind = Kind.new(kind)
  case kind
  when IsDefinition["string"]
    raise "not a string" unless object.is_a? String
  when IsDefinition["number"]
    raise "not a number" unless object.is_a? Numeric
  when IsDefinition["range"]
    raise "not a number" unless object.is_a? Numeric
    bottom, top = kind.limits!
    raise "value out of range" unless (bottom..top).include?(object)
  when IsDefinition["array"]
    raise "not an array" unless object.is_a? Array
    object.each do |entry|
      if kind.contents?
        schema_check( entry, kind.contents, schema )
      end
    end
  when IsDefinition["either"]
    kind.choices!.find_index do |choice|
      begin 
        schema_check( object, choice, schema )
        true
      rescue
        false
      end
    end or raise "does not match any of #{kind.choices.inspect}"
  when IsDefinition["enum"]
    kind.values!.find_index do |value|
      value == object
    end or raise "does not match any of #{kind.values.inspect}"
  when IsDefinition["tuple"]
    schema_check( object, "array", schema )
    raise "tuple is the wrong size" if object.length != kind.elements!.length
    kind.elements!.zip(object).each do |spec, value|
      schema_check( value, spec, schema )
    end
  when IsDefinition["integer"]
    schema_check( object, "number", schema )
    object.is_a?(Integer) or raise "#{object} is not an integer"
  else
    raise "Invalid definition #{kind.inspect}"
  end
end

