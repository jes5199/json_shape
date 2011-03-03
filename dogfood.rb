require 'rubygems'
require 'json'
require 'json_shape'

schema = JSON.parse( File.read( "schema_schema.js" ) )

JsonShape.schema_check( schema, "schema", schema )

