
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include AMEE::DataAbstraction

describe Term do
  before(:each) do
    
  end

  it "should return self if no unit or per unit attribute" do
    @term = Term.new { value 20 }
    @term.unit.should be_nil
    @term.per_unit.should be_nil
    @term.value.should eql 20
    new_term = @term.convert_unit(:unit => :t)
    new_term.should === @term
    new_term.value.should eql 20
    new_term.unit.should be_nil
    new_term.per_unit.should be_nil
  end

  it "should return self if not a numeric unit" do
    @term = Term.new { value 'plane'; unit :kg }
    @term.unit.label.should eql 'kg'
    @term.value.should eql 'plane'
    new_term = @term.convert_unit(:unit => :t)
    new_term.should === @term
  end

  it "should convert unit" do
    @term = Term.new { value 20; unit :kg }
    @term.unit.symbol.should eql 'kg'
    @term.value.should eql 20
    new_term = @term.convert_unit(:unit => :t)
    new_term.unit.symbol.should eql 't'
    new_term.value.should eql 0.020
  end

  it "should convert per unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    new_term = @term.convert_unit(:per_unit => :h)
    new_term.unit.symbol.should eql 'kg'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1200.0
  end

  it "should convert unit and per unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    new_term = @term.convert_unit( :unit => :t, :per_unit => :h )
    new_term.unit.symbol.should eql 't'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1.2000
  end

  it "should convert unit if value a string" do
    @term = Term.new { value "20"; unit :kg }
    @term.unit.symbol.should eql 'kg'
    @term.value.should eql "20"
    new_term = @term.convert_unit(:unit => :t)
    new_term.unit.symbol.should eql 't'
    new_term.value.should eql 0.020
  end

  it "should convert per unit if value a string" do
    @term = Term.new { value "20"; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql "20"
    new_term = @term.convert_unit(:per_unit => :h)
    new_term.unit.symbol.should eql 'kg'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1200.0
  end

  it "should convert unit and per unit if value a string" do
    @term = Term.new { value "20"; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql "20"
    new_term = @term.convert_unit( :unit => :t, :per_unit => :h )
    new_term.unit.symbol.should eql 't'
    new_term.per_unit.symbol.should eql 'h'
    new_term.value.should eql 1.2000
  end

  it "should raise error if trying to convert to non dimensionally equivalent unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    lambda{new_term = @term.convert_unit( :unit => :J, :per_unit => :h )}.should raise_error
  end

  it "should raise error if trying to convert to non dimensionally equivalent unit" do
    @term = Term.new { value 20; unit :kg; per_unit :min }
    @term.unit.symbol.should eql 'kg'
    @term.per_unit.symbol.should eql 'min'
    @term.value.should eql 20
    lambda{new_term = @term.convert_unit( :unit => :J, :per_unit => :h )}.should raise_error
  end
end

