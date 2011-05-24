require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include AMEE::DataAbstraction

describe TermsList do

  before(:each) do
    initialize_calculation_set
    calcs = []
    calcs << add_elec_calc(500,240)
    calcs << add_elec_calc(1000,480)
    calcs << add_elec_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list = @coll.terms
  end

  it "should initialize a terms list" do
    @list.should be_a AMEE::DataAbstraction::TermsList
  end

  it "full list should be homogeneous" do
    @list.should_not be_analogous
    @list.all? {|term| term.is_a? AMEE::DataAbstraction::Output }.should be_false
  end

  it "should filter class using dynamic methods" do
    @list = @list.outputs
    @list.all? {|term| term.is_a? AMEE::DataAbstraction::Output }.should be_true
    @list.labels.all? {|label| label == :co2 }.should be_true
    @list.should be_analogous
  end

  it "should filter type using dynamic method" do
    @list = @list.co2
    @list.all? {|term| term.is_a? AMEE::DataAbstraction::Output }.should be_true
    @list.labels.all? {|label| label == :co2 }.should be_true
    @list.should be_analogous
  end

  it "should recognize consistent units" do
    @list.co2.should be_analogous
    @list.co2.should be_homogeneous_units
    @list.co2.should be_homogeneous_per_units
  end
  
  it "should recognize consistent units" do
    @list.co2.first.unit 'lb'
    @list.co2[1].per_unit 'h'
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    @list.co2.should_not be_homogeneous_per_units
  end

  it "should standardize term units with predominant units" do
    @list.co2.first.unit 'lb'
    @list.co2.first.value.should eql 240
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    list = @list.co2.standardize_units
    list.should be_homogeneous
    list.should be_homogeneous_units
    list.first.unit 't'
    list.first.value.should be_close 0.1088621688,0.001
  end

  it "should standardize term units" do
    @list.co2.first.per_unit 'min'
    @list.co2[1].per_unit 'h'
  end

  it "should sum terms" do
    @list.co2.sum.to_s.should eql "1320.0 t"
  end

  it "should sum terms where units differ" do
    @list.co2.first.unit 'kg'
    @list.co2.sum.to_s.should eql "1080.24 t"
  end

  it "should sum terms and change unit" do
    @list.co2.sum(:kg).to_s.should eql "1320000.0 kg"
  end

  it "should sum terms where units differ and change return unit" do
    @list.co2.first.unit 'kg'
    @list.co2.sum(:lb).to_s.should eql "2381521.54102592 lb"
  end

  it "should average terms" do
    @list.co2.mean.to_s.should eql "440.0 t"
  end

  it "should discover predominant unit" do
    @list.co2.predominant_unit.should eql 't'
    @list.usage.predominant_unit.should eql 'kWh'
  end

  it "should sort by value changing list in place" do
    @list=@list.co2
    @list.first.value.should eql 240
    @list[1].value.should eql 480
    @list.last.value.should eql 600
    @list.reverse!
    @list.first.value.should_not eql 240
    @list.last.value.should_not eql 600
    @list.sort_by_value!
    @list.first.value.should eql 240
    @list[1].value.should eql 480
    @list.last.value.should eql 600
  end


  it "should sort by value creating new list" do
    @list=@list.co2
    @list.first.value.should eql 240
    @list[1].value.should eql 480
    @list.last.value.should eql 600
    @list.reverse!
    @list.first.value.should_not eql 240
    @list.last.value.should_not eql 600
    list = @list.sort_by_value
    list.first.value.should eql 240
    list[1].value.should eql 480
    list.last.value.should eql 600
  end

  it "should return median of list" do
    @list.co2.median.to_s.should eql "480 t"
  end
end

