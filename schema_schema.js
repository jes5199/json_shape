{
  "schema" : ["dictionary", {"contents": "definition"}],
  "definition" : ["either", {"choices": ["definition_name", "definition_pair"]}],

  "builtin_type" : ["enum", {
    "values": ["string", "number", "boolean", "null", "undefined", "array", "object", "anything", "integer", "enum", "range", "tuple", "dictionary", "either", "restrict" ]
  }],

  "definition_name" : [ "either", {
    "choices": [ "custom_type", "builtin_type_with_optional_parameters", "builtin_type_without_parameters" ]
  } ],

  "parameterized_type" : ["either", {"choices": ["builtin_type_with_optional_parameters", "builtin_type_with_mandatory_parameters"] }],
  "definition_pair" : ["tuple", {"elements": ["parameterized_type", "definition_parameters"]}],

  "definition_parameters" : ["either", {"choices" :
    [
      "array_parameters",
      "object_parameters",
      "dictionary_parameters",
      "restrict_parameters",
      "enum_parameters",
      "range_parameters",
      "tuple_parameters",
      "either_parameters"
    ]
  }],

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
  }],

  "optional_definition": [ "either", { "choices": [ "undefined", "definition" ] } ],
  "optional_definitions": [ "either", { "choices": [ "undefined", 
    ["array", {"contents": "definition"}]
  ] } ],

  "array_parameters": [ "object", { "contents": "optional_definition" } ],

  "object_parameters": [ "dictionary", { "contents": "definition" } ],

  "dictionary_parameters": [ "object", {"contents": "optional_definition" } ],

  "restrict_parameters": [ "object", {
    "require" : "optional_definitions",
    "reject"  : "optional_definitions"
  }],

  "enum_parameters": [ "object", {
    "values" : ["array", {"contents": "anything"}]
  }],

  "range_parameters": [ "object", {
    "limits" : ["tuple", {"elements": ["number", "number"]}]
  }],

  "tuple_parameters": [ "object", {
    "elements" : ["array", {"contents": "definition"}]
  }],

  "either_parameters": [ "object", {
    "choices" : ["array", {"contents": "definition"}]
  }]

}
