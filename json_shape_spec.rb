require 'json_shape'

describe "JsonShape" do
  describe "the anything type" do
    it "should match anything" do
      JsonShape.new("anything").check( "x" )
      JsonShape.new("anything").check(   1 )
      JsonShape.new("anything").check(  [] )
      JsonShape.new("anything").check(  {} )
    end
  end

  describe "the literal type" do
    it "should match literal matches" do
      JsonShape.new(["literal", "x"] ).check( "x")
      JsonShape.new( ["literal", {"x"=>"y"}] ).check( {"x"=>"y"})
    end

    it "should cope with false" do
      JsonShape.new( ["literal", false] ).check( false)
      lambda { JsonShape.new( ["literal", false] ).check( true) }.should raise_error
    end

    it "should not match if the literal does not match" do
      lambda { JsonShape.new( ["literal", {"x" => "y"}] ).check( "x") }.should raise_error
      lambda { JsonShape.new( ["literal", {"x"=>"z"}] ).check( {"x"=>"y"}) }.should raise_error
      lambda { JsonShape.new( ["literal", "1"] ).check( 1) }.should raise_error
    end
  end

  describe "the nullable type" do
    it "should match definition matches" do
      JsonShape.new( ["nullable", "string"] ).check( "x")
      JsonShape.new( ["nullable", ["literal", {"x"=>"y"}]] ).check( {"x"=>"y"})
    end

    it "should match nulls" do
      JsonShape.new( ["nullable", "string"] ).check( nil)
      JsonShape.new( ["nullable", ["literal", {"x"=>"y"}]] ).check( nil)
    end

    it "should not match unmatching subdefinitions" do
      lambda{ JsonShape.new( ["nullable", "number"] ).check( "x") }.should raise_error
    end
  end


  describe "the 'string' type" do
    it "should validate strings" do
      JsonShape.new( "string" ).check( "x")
    end
    it "should reject numbers" do
      lambda { JsonShape.new( "string" ).check( 1) }.should raise_error
    end
    it "should reject objects" do
      lambda { JsonShape.new( "string" ).check( {}) }.should raise_error
    end
    it "should reject null" do
      lambda { JsonShape.new( "string" ).check( nil) }.should raise_error
    end
    it "should reject arrays" do
      lambda { JsonShape.new( "string" ).check( ["a"]) }.should raise_error
    end
    it "should reject bools" do
      lambda { JsonShape.new( "string" ).check( true) }.should raise_error
      lambda { JsonShape.new( "string" ).check( false) }.should raise_error
    end

    describe "with parameters" do
      it "should validate strings" do
        JsonShape.new( ["string", {}] ).check( "x")
      end

      it "should accept strings matching a supplied regex" do
        JsonShape.new( ["string", {"matches" => '^\w+;\w+-\w+$'}] ).check( "my;fancy-string")
      end

      it "should reject strings not matching a supplied regex" do
        lambda { JsonShape.new( ["string", {"matches" => '^\w+;\w+-\w+$'}] ).check( "my;fancy-string with.other/characters") }.should raise_error
      end
    end
  end

  describe "the array type" do
    it "should accept arrays" do
      JsonShape.new( "array" ).check(  [1])
    end
    it "should accept arrays of the right type" do
      JsonShape.new( ["array", {"contents" => "number"}] ).check(  [1])
    end
    it "should reject arrays of the wrong type" do
      lambda { JsonShape.new( ["array", {"contents" => "number"}] ).check(  [[]]) }.should raise_error
    end
    it "should allow tests on array length" do
      JsonShape.new( ["array", {"length" => ["literal", 1]}] ).check(  [1])
      lambda { JsonShape.new( ["array", {"length" => ["literal", 2]}] ).check(  [1]) }.should raise_error
    end
  end

  describe "the either type" do
    it "should accept any one of the given subtypes" do
      JsonShape.new( ["either", {"choices" => ["array", "number"]}] ).check( [])
      JsonShape.new( ["either", {"choices" => ["array", "number"]}] ).check(  1)
    end

    it "should reject an unlisted subtype" do
      lambda{ JsonShape.new( ["either", {"choices" => ["array", "number"]}] ).check(  false) }.should raise_error
    end
  end

  describe "the enum type" do
    it "should accept any of the given values" do
      JsonShape.new( ["enum", {"values" => ["hello", "goodbye"]}] ).check(    "hello")
      JsonShape.new( ["enum", {"values" => ["hello", "goodbye"]}] ).check(  "goodbye")
    end
    it "should reject any other value" do
      lambda { JsonShape.new( ["enum", {"values" => ["hello", "goodbye"]}] ).check(    "elephant") }.should raise_error
      lambda { JsonShape.new( ["enum", {"values" => ["hello", "goodbye"]}] ).check(            {}) }.should raise_error
    end
  end

  describe "the tuple type" do
    it "should accept an array of the given types" do
      JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["array", {"contents" => "number" }]  ]}] ).check( ["a", 1, [2]])
    end

    it "should not accept anything that isn't an array" do
      lambda {
        JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["array", {"contents" => "number" }]  ]}] ).check( {})
      }.should raise_error
    end
    it "should not accept an array that is too short" do
      lambda {
        JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["array", {"contents" => "number" }]  ]}] ).check( ["a", 1])
      }.should raise_error
    end
    it "should not accept an array that is too long" do
      lambda {
        JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["array", {"contents" => "number" }]  ]}] ).check( ["a", 1, [2], 5])
      }.should raise_error
    end
    it "should not accept an array where an entry has the wrong type" do
      lambda {
        JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["array", {"contents" => "number" }]  ]}] ).check( ["a", 1, ["b"]])
      }.should raise_error
    end
    it "should allow optional elements at the end" do
      JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["optional", ["array", {"contents" => "number" }]]  ]}] ).check( ["a", 1])
      JsonShape.new( ["tuple", {"elements" => ["string", ["integer", {"min" => 0, "max" => 1}], ["optional", ["array", {"contents" => "number" }]]  ]}] ).check( ["a", 1, [2]])
    end
  end

  describe "the number type" do
    it "should accept integers" do
      JsonShape.new( "number" ).check( 1)
    end
    it "should accept floats" do
      JsonShape.new( "number" ).check( 1.0)
    end
    it "should accept numbers within specified boundaries" do
      JsonShape.new( ["number", {"min" => 0.5, "max" => 5.2}] ).check( 3.5)
    end
    it "should reject numbers less than the minimum" do
      lambda { JsonShape.new( ["number", {"min" => 9000}] ).check( 8999.9) }.should raise_error
    end
    it "should reject numbers greater than the maximum" do
      lambda { JsonShape.new( ["number", {"max" => 3}] ).check( 3.14) }.should raise_error
    end
  end
  describe "the integer type" do
    it "should accept integers" do
      JsonShape.new( "integer" ).check( 1)
    end
    it "should reject floats" do
      lambda{ JsonShape.new( "integer" ).check( 1.0) }.should raise_error
    end
    it "should reject strings" do
      lambda{ JsonShape.new( "integer" ).check( "1") }.should raise_error
    end
    it "should accept integers within specified boundaries" do
      JsonShape.new( ["integer", {"min" => 0, "max" => 100}] ).check( 50)
    end
    it "should reject integers less than the minimum" do
      lambda { JsonShape.new( ["integer", {"min" => 100}] ).check( 50) }.should raise_error
    end
    it "should reject integers greater than the minimum" do
      lambda { JsonShape.new( ["integer", {"max" => 0}] ).check( 50) }.should raise_error
    end
  end

  describe "the object type" do
    it "should accept an object" do
      JsonShape.new( "object" ).check( {})
    end

    it "should accept an object with the correct members" do
      JsonShape.new( ["object", {"members" => {"a" => "integer" } } ] ).check( {"a" => 1})
    end

    it "should reject an object with missing members" do
      lambda { JsonShape.new( ["object", {"members" => {"a" => "integer", "b" => "integer" } } ] ).check( {"a" => 1}) }.should raise_error
    end

    it "should reject an object with incorrect members" do
      lambda { JsonShape.new( ["object", {"members" => {"a" => "string" } } ] ).check( {"a" => 1}) }.should raise_error
    end

    it "should accept an object with missing members if they are of type undefined" do
      JsonShape.new( ["object", {"members" => {"a" => "integer", "b" => "undefined" } } ] ).check( {"a" => 1})
    end

    it "should accept an object with missing members if they are optional" do
      JsonShape.new( ["object", {"members" => {"a" => "integer", "b" => ["optional", "integer"] } } ] ).check( {"a" => 1})
    end

    it "should reject an object with extra members" do
      lambda { JsonShape.new( ["object", {"members" => {"a" => "integer" } } ] ).check( {"a" => 1, "b" => 2}) }.should raise_error
    end
  end

  describe "the dictionary type" do
    it "should accept an object" do
      JsonShape.new( "dictionary" ).check( {})
    end

    it "should accept values of the correct type" do
      JsonShape.new( ["dictionary", {"contents" => "number"}] ).check(  {"a" => 1})
    end

    it "should reject values of the wrong type" do
      lambda { JsonShape.new( ["dictionary", {"contents" => "number"}] ).check(  {"a" => []}) }.should raise_error
    end

    it "should respect custom types" do
      JsonShape.new( ["dictionary", {"contents" => "foo"}], {"foo" => "number"} ).check(  {"a" => 1})
    end

    it "should accept dictionaries whose keys match the type specified" do
      JsonShape.new( ["dictionary", {"keys" => ["string", {"matches" => '^\w+-\w+\.\w+$'} ] } ] ).check( {"foo-bar.baz" => "my_value"})
    end

    it "should reject dictionaries whose keys do not match the type specified" do
      lambda { JsonShape.new( ["dictionary", {"keys" => ["string", {"matches" => '^\w+-\w+\.\w+$'} ] } ] ).check( {"foo.bar-baz" => "my_value"}) }.should raise_error(/does not match/)
    end
  end

  describe "the boolean type" do
    it "should accept true" do
      JsonShape.new( "boolean" ).check( true)
    end
    it "should accept false" do
      JsonShape.new( "boolean" ).check( false)
    end
    it "should reject other values" do
      lambda{ JsonShape.new( "boolean" ).check( 1) }.should raise_error
    end
  end

  describe "the null type" do
    it "should accept null" do
      JsonShape.new( "null" ).check( nil)
    end
    it "should reject other values" do
      lambda{ JsonShape.new( "null" ).check( 1) }.should raise_error
    end
  end

  describe "the restrict type" do
    it "should accept a value that satisfies multiple requirements" do
      JsonShape.new( ["restrict",
        {
          "require" => [
            "integer",
            ["integer", {"min" => 1,  "max" => 5 } ],
            ["integer", {"min" => -2, "max" => 2 } ],
            ["enum",    {"values" => [-2, 2]     } ]
          ]
        }
      ] ).check(2)
    end
    it "should reject a value that fails to satisfy a requirement" do
      lambda {
        JsonShape.new( ["restrict",
          {
            "require" => [
              "integer",
              ["integer", {"min" => 1,  "max" => 5} ],
              ["integer", {"min" => -2, "max" => 2} ],
              ["enum",    {"values" => [-2, nil]  } ]
            ]
          }
        ] ).check(2)
      }.should raise_error
    end
    it "should reject a value that satisfies a rejection constraint" do
      lambda {
        JsonShape.new( ["restrict",
            {
              "reject" => [
                ["integer", {"min" => -2, "max" => 2} ],
                ["enum",    {"values" => [-2, nil]  } ]
              ]
            }
          ]
        ).check(2)
      }.should raise_error
    end

    it "should accept a value that satisfies requirements and avoids rejections" do
      JsonShape.schema_check( 2,
        ["restrict",
          {
            "require" => [
              "integer",
              ["integer", {"min" => 1,  "max" => 5 } ],
              ["integer", {"min" => -2, "max" => 2 } ],
              ["enum",    {"values" => [-2, 2]     } ]
            ],
            "reject" => [
              ["number", {"min" => -2, "max" => 1.9} ],
              ["enum",   {"values" => [-2, nil]    } ]
            ]
          }
        ]
      )
    end

    it "should reject a value that satisfies requirements but violates a rejection rule" do
      lambda {
        JsonShape.schema_check( 2,
          ["restrict",
            {
              "require" => [
                "integer",
                ["integer", {"min" => 1, "max" => 5 } ],
                ["integer", {"min" => -2, "max" => 2} ],
                ["enum",    {"values" => [-2, 2]    } ]
              ],
              "reject" => [
                ["number", {"min" => -2, "max" => 1.9} ],
                ["enum",   {"values" => [-2, 2]      } ]
              ]
            }
          ]
        )
      }.should raise_error
    end

    it "should reject a value that fails to satisfy requirements but doesn't violate a rejection rule" do
      lambda {
        JsonShape.schema_check( 2,
          ["restrict",
            {
              "require" => [
                "integer",
                ["integer", {"min" => 1, "max" => 5   } ],
                ["number",  {"min" => -2, "max" => 1.9} ],
                ["enum",    {"values" => [-2, 2]      } ]
              ],
              "reject" => [
                ["number", {"min" => -2, "max" => 1.9} ],
                ["enum",   {"values" => [-2, nil]    } ]
              ]
            }
          ]
        )
      }.should raise_error
    end

  end

  describe "named types" do
    it "should work" do
      JsonShape.schema_check( 2, "foo", { "foo" => "integer" } )
    end

    it "should enforce the refered type" do
      lambda { JsonShape.schema_check( 2, "foo", { "foo" => "array" } ) }.should raise_error
    end

    it "should work recursively" do
      JsonShape.schema_check( 2, "foo", { "foo" => "bar", "bar" => ["integer", {"min" => -1, "max" => 2} ] } )
      lambda { JsonShape.schema_check( 3, "foo", { "foo" => "bar", "bar" => ["integer", {"min" => -1, "max" => 2} ] } ) }.should raise_error
    end

    it "should not allow undefined types" do
      lambda { JsonShape.schema_check( 2, "bar", { "foo" => "integer" } ) }.should raise_error
    end
  end
end
