class JsonShape
  class Kind
    attr :name
    attr :params

    def initialize(kind)
      if kind.is_a?(Array)
        @name, @params = kind
      else
        @name = kind
        @params = {}
      end
    end

    def inspect
      [name, params].inspect
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

    def is_definition?(name)
      self.name == name
    end
  end

  class Failure < ArgumentError
    def initialize( message, path )
      @message, @path = message, path
    end

    def to_s
      if @path.empty?
        message
      else
        "#{ @message } at #{ @path.join('/') }"
      end
    end

    def message
      to_s
    end
  end

  def initialize( kind, schema = {}, path = [] )
    @kind = Kind.new(kind)
    @schema = schema
    @path = path
  end
  attr :kind

  def fail( message )
    raise Failure.new( message, @path )
  end

  def delve( key, kind )
    JsonShape.new( kind, @schema, @path + [key] )
  end

  def refine( kind )
    JsonShape.new( kind, @schema, @path )
  end

  def check( object )
    case
    # simple values
    when kind.is_definition?("string")
      fail("not a string") unless object.is_a? String
      if kind.matches? and object !~ Regexp.new(kind.matches)
        fail( "does not match /#{kind.matches}/" )
      end
    when kind.is_definition?("number")
      fail( "not a number" ) unless object.is_a? Numeric
      fail( "less than min #{kind.min}" ) if kind.min? and object < kind.min
      fail( "greater than max #{kind.max}" ) if kind.max? and object > kind.max
    when kind.is_definition?("boolean")
      fail( "not a boolean" ) unless object == true || object == false
    when kind.is_definition?("null")
      fail( "not null" ) unless object == nil
    when kind.is_definition?("undefined")
      object == :undefined or fail( "is not undefined" )

    # complex values
    when kind.is_definition?("array")
      fail( "not an array" ) unless object.is_a? Array
      if kind.contents?
        object.each_with_index do |entry, i|
          delve( i, kind.contents ).check( entry )
        end
      end
      if kind.length?
        delve( ".length", kind.length ).check(object.length)
      end

    when kind.is_definition?("object")
      object.is_a?(Hash) or fail( "not an object" )
      if kind.members?
        kind.members.each do |name, spec|
          val = object.has_key?(name) ? object[name] : :undefined
          next if val == :undefined and kind.allow_missing
          delve( name, spec ).check(val)
        end
        if kind.allow_extra != true
          extras = object.keys - kind.members.keys
          fail( "#{extras.inspect} are not valid members" ) if extras != []
        end
      end

    # obvious extensions
    when kind.is_definition?("anything")
      object != :undefined or fail( "is not defined" )

    when kind.is_definition?("literal")
      object == kind.params or fail( "doesn't match" )

    when kind.is_definition?("integer")
      refine( ["number", kind.params] ).check(object)
      object.is_a?(Integer) or fail( "is not an integer" )

    when kind.is_definition?("enum")
      kind.values!.find_index do |value|
        value == object
      end or fail( "does not match any choice" )

    when kind.is_definition?("tuple")
      refine( "array" ).check( object )
      fail( "tuple is the wrong size" ) if object.length > kind.elements!.length
      undefineds = [:undefined] * (kind.elements!.length - object.length)
      kind.elements!.zip(object + undefineds).each_with_index do |pair, i|
        spec, value = pair
        delve( i, spec ).check( value )
      end

    when kind.is_definition?("dictionary")
      refine( "object" ).check( object )

      object.each do |key, value|
        if kind.contents?
          delve( key, kind.contents ).check(value)
        end
        if kind.keys?
          delve( key, kind.keys ).check( key )
        end
      end

    # set theory
    when kind.is_definition?("either")
      kind.choices!.find_index do |choice|
        begin
          refine( choice ).check( object )
          true
        rescue Failure
          false
        end
      end or fail( "does not match any choice" )

    when kind.is_definition?("optional")
      object == :undefined or refine( kind.params ).check( object )

    when kind.is_definition?("nullable")
      object == nil or refine( kind.params ).check( object )

    when kind.is_definition?("restrict")
      if kind.require?
        kind.require.each do |requirement|
          refine( requirement ).check( object )
        end
      end
      if kind.reject?
        kind.reject.each do |rule|
          begin
            refine( rule ).check( object )
            false
          rescue Failure
            true
          end or fail( "violates #{rule.inspect}" )
        end
      end

    # custom types
    when @schema[kind.name]
      refine( @schema[kind.name] ).check( object )
    else
      raise "Invalid definition #{kind.inspect}"
    end
  end

  def self.schema_check( object, kind, schema = {}, path = [])
    self.new( kind, schema, path ).check(object)
  end
end

if __FILE__ == $0
  require 'rubygems'
  require 'json'

  schema = JSON.parse( File.read( ARGV[0] ) )

  type = ARGV[1]

  if ARGV[2]
    stream = File.open(ARGV[2])
  else
    stream = STDIN
  end

  data = JSON.parse( stream.read )

  JsonShape.schema_check( data, type, schema )
end
