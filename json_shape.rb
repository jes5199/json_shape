class JsonShape
  class Parameters
    attr :name
    attr :params

    def initialize(parameters)
      if parameters.is_a?(Array)
        @name, @params = parameters
      else
        @name = parameters
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

  ###########################
  # simple values
  ###########################

  class StringRule < JsonShape
    def check(object)
      fail("not a string") unless object.is_a? String
      if parameters.matches? and object !~ Regexp.new(parameters.matches)
        fail( "does not match /#{parameters.matches}/" )
      end
    end
  end

  class NumberRule < JsonShape
    def check(object)
      fail( "not a number" ) unless object.is_a? Numeric
      fail( "less than min #{parameters.min}" ) if parameters.min? and object < parameters.min
      fail( "greater than max #{parameters.max}" ) if parameters.max? and object > parameters.max
    end
  end

  class BooleanRule < JsonShape
    def check( object )
      fail( "not a boolean" ) unless object == true || object == false
    end
  end

  class NullRule < JsonShape
    def check( object )
      fail( "not null" ) unless object == nil
    end
  end

  class UndefinedRule < JsonShape
    def check( object )
      object == :undefined or fail( "is not undefined" )
    end
  end

  ###########################
  # complex values
  ###########################

  class ArrayRule < JsonShape
    def check( object )
      fail( "not an array" ) unless object.is_a? Array
      if parameters.contents?
        object.each_with_index do |entry, i|
          delve( i, parameters.contents ).check( entry )
        end
      end
      if parameters.length?
        delve( ".length", parameters.length ).check(object.length)
      end
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

  class ObjectRule < JsonShape
    def check(object)
      object.is_a?(Hash) or fail( "not an object" )
      if parameters.members?
        parameters.members.each do |name, spec|
          val = object.has_key?(name) ? object[name] : :undefined
          next if val == :undefined and parameters.allow_missing
          delve( name, spec ).check(val)
        end
        if parameters.allow_extra != true
          extras = object.keys - parameters.members.keys
          fail( "#{extras.inspect} are not valid members" ) if extras != []
        end
      end
    end
  end

  ###########################
  # obvious extensions
  ###########################

  class AnythingRule < JsonShape
    def check(object)
      object != :undefined or fail( "is not defined" )
    end
  end

  class LiteralRule < JsonShape
    def check(object)
      object == parameters.params or fail( "doesn't match" )
    end
  end

  class IntegerRule < JsonShape
    def check(object)
      refine( ["number", parameters.params] ).check(object)
      object.is_a?(Integer) or fail( "is not an integer" )
    end
  end

  class EnumRule < JsonShape
    def check(object)
      parameters.values!.find_index do |value|
        value == object
      end or fail( "does not match any choice" )
    end
  end

  class TupleRule < JsonShape
    def check(object)
      refine( "array" ).check( object )
      fail( "tuple is the wrong size" ) if object.length > parameters.elements!.length
      undefineds = [:undefined] * (parameters.elements!.length - object.length)
      parameters.elements!.zip(object + undefineds).each_with_index do |pair, i|
        spec, value = pair
        delve( i, spec ).check( value )
      end
    end
  end

  class DictionaryRule < JsonShape
    def check(object)
      refine( "object" ).check( object )

      object.each do |key, value|
        if parameters.contents?
          delve( key, parameters.contents ).check(value)
        end
        if parameters.keys?
          delve( key, parameters.keys ).check( key )
        end
      end
    end
  end

  ###########################
  # set theory
  ###########################

  class EitherRule < JsonShape
    def check(object)
      parameters.choices!.find_index do |choice|
        begin
          refine( choice ).check( object )
          true
        rescue Failure
          false
        end
      end or fail( "does not match any choice" )
    end
  end

  class OptionalRule < JsonShape
    def check(object)
      object == :undefined or refine( parameters.params ).check( object )
    end
  end

  class NullableRule < JsonShape
    def check(object)
      object == nil or refine( parameters.params ).check( object )
    end
  end

  class RestrictRule < JsonShape
    def check(object)
      if parameters.require?
        parameters.require.each do |requirement|
          refine( requirement ).check( object )
        end
      end
      if parameters.reject?
        parameters.reject.each do |rule|
          begin
            refine( rule ).check( object )
            false
          rescue Failure
            true
          end or fail( "violates #{rule.inspect}" )
        end
      end
    end
  end

  def self.new( parameters, schema = {}, path = [] )
    return super if self != JsonShape

    _parameters = Parameters.new(parameters)
    return super unless _parameters.name =~ /^[a-z]+$/
    if klass = const_get( "#{_parameters.name.capitalize}Rule" ) rescue nil
      return klass.new( parameters, schema, path )
    end

    super
  end

  def initialize( parameters, schema = {}, path = [] )
    @parameters = Parameters.new(parameters)
    @schema = schema
    @path = path

    if klass = self.klass.const_get( "#{parameters.name.capitalize}Rule" ) rescue nil
      return klass.new( parameters, schema, path )
    end
  end
  attr :parameters

  def fail( message )
    raise Failure.new( message, @path )
  end

  def delve( key, parameters )
    JsonShape.new( parameters, @schema, @path + [key] )
  end

  def refine( parameters )
    JsonShape.new( parameters, @schema, @path )
  end

  def check( object )
    case
    # custom types
    when @schema[parameters.name]
      refine( @schema[parameters.name] ).check( object )
    else
      raise "Invalid definition #{parameters.inspect}"
    end
  end

  def self.schema_check( object, parameters, schema = {}, path = [])
    self.new( parameters, schema, path ).check(object)
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
