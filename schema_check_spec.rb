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
end
