{
  "schema" : ["dictionary", {"contents": "definitions"}],
  "definitions" : ["either", {"choices": ["definition_name", "definition_pair"]}],

  "builtin_type" : ["enum", {
    "values": ["string", "number", "boolean", "null", "undefined", "array", "object", "anything", "integer", "enum", "range", "tuple", "dictionary", "either", "restrict" ]
  }],

  "definition_name" : [ "either", {
    "choices": [ "custom_type", "builtin_type_with_optional_parameters", "builtin_type_without_parameters" ]
  } ],

  "parameterized_type" : ["either", {"choices": ["builtin_type_with_optional_parameters", "builtin_type_with_mandatory_parameters"] }],
  "definition_pair" : ["tuple", {"elements": ["parameterized_type", "definition_parameters"]}],

  "definition_parameters" : "dictionary",

  "custom_type" : ["restrict", {
    "require": ["string"],
    "reject":  ["builtin_type"]
  }],

  "builtin_type_without_parameters" : ["enum", {
    "values": ["string", "number", "boolean", "null", "undefined", "anything", "integer"]
  }],

  "builtin_type_with_optional_parameters" :  ["enum", {
    "values": ["array", "object", "dictionary", "restrict"]
  }],

  "builtin_type_with_mandatory_parameters" : ["enum", {
    "values": ["enum", "range", "tuple", "either"]
  }]
}
