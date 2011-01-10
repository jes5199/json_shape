require 'rubygems'
require 'json'
require 'schema_check'

schema = JSON.parse( File.read( "schema_schema.js" ) )

schema_check( schema, "schema", schema )

