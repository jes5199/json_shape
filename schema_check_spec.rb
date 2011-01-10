require 'schema_check'

describe "schema_check" do
  describe "the 'string' type" do 
    it "should validate strings" do
      schema_check( "x", "string" )
    end
    it "should reject numbers" do
      lambda { schema_check( 1, "string" ) }.should raise_error
    end
    it "should reject objects" do
      lambda { schema_check( {}, "string" ) }.should raise_error
    end
    it "should reject null" do
      lambda { schema_check( nil, "string" ) }.should raise_error
    end
    it "should reject arrays" do
      lambda { schema_check( ["a"], "string" ) }.should raise_error
    end
    it "should reject bools" do
      lambda { schema_check( true, "string" ) }.should raise_error
      lambda { schema_check( false, "string" ) }.should raise_error
    end

    describe "with parameters" do
      it "should validate strings" do
        schema_check( "x", ["string", {}] )
      end
    end
  end

  describe "the range predicate" do
    it "should reject strings" do
      lambda { schema_check( "1", ["range", {}] ) }.should raise_error
    end

    it "should accept numbers in the range" do
      schema_check(   1, ["range", {"limits" => [0,3]}] )
      schema_check(   0, ["range", {"limits" => [0,3]}] )
      schema_check(   3, ["range", {"limits" => [0,3]}] )
      schema_check( 2.8, ["range", {"limits" => [0,3]}] )
      schema_check( 3.0, ["range", {"limits" => [0,3]}] )
    end

    it "should reject numbers out of the range" do
      lambda { schema_check(  -1, ["range", {"limits" => [0,3]}] ) }.should raise_error
      lambda { schema_check(   4, ["range", {"limits" => [0,3]}] ) }.should raise_error
      lambda { schema_check( 3.1, ["range", {"limits" => [0,3]}] ) }.should raise_error
    end
  end

  describe "the array type" do
    it "should accept arrays" do
      schema_check(  [1], "array" )
    end
    it "should accept arrays of the right type" do
      schema_check(  [1], ["array", {"contents" => ["number"]}] )
    end
    it "should reject arrays of the wrong type" do
      lambda { schema_check(  [[]], ["array", {"contents" => ["number"]}] ) }.should raise_error
    end
  end

  describe "the either type" do
    it "should accept any one of the given subtypes" do
      schema_check( [], ["either", {"choices" => ["array", "number"]}] )
      schema_check(  1, ["either", {"choices" => ["array", "number"]}] )
    end

    it "should reject an unlisted subtype" do
      lambda{ schema_check(  false, ["either", {"choices" => ["array", "number"]}] ) }.should raise_error
    end
  end

  describe "the enum type" do
    it "should accept any of the given values" do
      schema_check(    "hello", ["enum", {"values" => ["hello", "goodbye"]}] )
      schema_check(  "goodbye", ["enum", {"values" => ["hello", "goodbye"]}] )
    end
    it "should reject any other value" do
      lambda { schema_check(    "elephant", ["enum", {"values" => ["hello", "goodbye"]}] ) }.should raise_error
      lambda { schema_check(            {}, ["enum", {"values" => ["hello", "goodbye"]}] ) }.should raise_error
    end
  end

  describe "the tuple type" do
    it "should accept an array of the given types" do
      schema_check( ["a", 1, [2]], ["tuple", {"elements" => ["string", ["range", {"limits" => [0,1]}], ["array", {"contents" => "number" }]  ]}] )
    end

    it "should not accept anything that isn't an array" do
      lambda {
        schema_check( {}, ["tuple", {"elements" => ["string", ["range", {"limits" => [0,1]}], ["array", {"contents" => "number" }]  ]}] )
      }.should raise_error
    end
    it "should not accept an array that is too short" do
      lambda {
        schema_check( ["a", 1], ["tuple", {"elements" => ["string", ["range", {"limits" => [0,1]}], ["array", {"contents" => "number" }]  ]}] )
      }.should raise_error
    end
    it "should not accept an array that is too long" do
      lambda {
        schema_check( ["a", 1, [2], 5], ["tuple", {"elements" => ["string", ["range", {"limits" => [0,1]}], ["array", {"contents" => "number" }]  ]}] )
      }.should raise_error
    end
    it "should not accept an array where an entry has the wrong type" do
      lambda {
        schema_check( ["a", 1, ["b"]], ["tuple", {"elements" => ["string", ["range", {"limits" => [0,1]}], ["array", {"contents" => "number" }]  ]}] )
      }.should raise_error
    end
  end
  describe "the integer type" do
    it "should accept integers" do
      schema_check( 1, "integer" )
    end
    it "should reject floats" do
      lambda{ schema_check( 1.0, "integer" ) }.should raise_error
    end
    it "should reject strings" do
      lambda{ schema_check( "1", "integer" ) }.should raise_error
    end
  end
end
