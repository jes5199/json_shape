{
  "schema" : ["dictionary", {"contents": "definitions"}],
  "definitions" : ["either", {"choices": ["definition_name", "definition_pair"]}],
  "definition_name" : "string",
  "definition_pair" : ["tuple", {"elements": ["definition_name", "definition_parameters"]}],
  "definition_parameters" : "dictionary"
}
