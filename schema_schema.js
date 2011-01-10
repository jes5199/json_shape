{
  "schema" : ["dictionary", {"contents": "definitions"}],
  "definitions" : ["either", {"choices": ["definition_name", "definition_pair"]}],

  "builtin_type" : ["enum", {
    "values": ["string", "number", "boolean", "null", "undefined", "array", "object", "anything", "integer", "enum", "range", "tuple", "dictionary", "either", "restrict" ]
  }],

  "definition_name" : "string",
  "definition_pair" : ["tuple", {"elements": ["builtin_type", "definition_parameters"]}],
  "definition_parameters" : "dictionary"

}
