require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include AMEE::DataAbstraction

describe CalculationCollection do

  before(:each) do
    initialize_calculation_set
    @calcs = []
    @calcs << add_elec_calc(500,240)
    @calcs << add_elec_calc(1000,480)
    @calcs << add_elec_calc(1234,600)
    @coll = CalculationCollection.new @calcs
  end

  it "should add calcs to collection" do
    @coll.should be_a CalculationCollection
    @coll.first.should be_a AMEE::DataAbstraction::OngoingCalculation
    @coll.size.should eql 3
  end

  it "should be homogeneous" do
    @coll.should be_homogeneous
    @coll.should_not be_heterogeneous
  end

  it "should be homogeneous" do
    @coll << add_transport_calc(1000,231)
    @coll.should_not be_homogeneous
    @coll.should be_heterogeneous
  end

  it "should hold all calculation terms" do
    terms = @coll.terms
    terms.should be_a AMEE::DataAbstraction::TermsList
    terms.size.should eql 9
  end

  it "should return all like terms dynamically" do
    terms = @coll.co2
    terms.should be_a AMEE::DataAbstraction::TermsList
    terms.size.should eql 3
    terms.labels.uniq.should eql [:co2]
  end

  it "should delegate selector methods" do
    terms = @coll.outputs
    terms.all? {|term| term.is_a? AMEE::DataAbstraction::Output }.should be_true
  end

  it "should sum term values with homegeneous calcs" do
    @coll.co2.sum.to_s.should eql "1320.0 t"
    @coll.co2.mean.to_s.should eql "440.0 t"
    @coll.usage.sum.to_s.should eql "2734.0 kWh"
  end
  
  it "should sum term values with heterogeneous calcs" do
    @coll << add_transport_calc(1000,231)
    @coll.co2.sum.to_s.should eql "1551.0 t"
    @coll.distance.sum.to_s.should eql "1000.0 km"
    @coll.usage.sum.to_s.should eql "2734.0 kWh"
  end

  it "should sort self by specified term" do
    @coll.inspect.should eql "[electricity : [\"Argentina\",500,240], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",1234,600]]"
    @coll.reverse!
    @coll.inspect.should eql "[electricity : [\"Argentina\",1234,600], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",500,240]]"
    @coll.sort_by_co2!
    @coll.inspect.should eql "[electricity : [\"Argentina\",500,240], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",1234,600]]"
    @coll.reverse!
    @coll.inspect.should eql "[electricity : [\"Argentina\",1234,600], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",500,240]]"
    @coll.sort_by_usage!
    @coll.inspect.should eql "[electricity : [\"Argentina\",500,240], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",1234,600]]"
  end

  it "should sort by specified term and return new" do
    @coll.inspect.should eql "[electricity : [\"Argentina\",500,240], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",1234,600]]"
    @coll.reverse!
    @coll.inspect.should eql "[electricity : [\"Argentina\",1234,600], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",500,240]]"
    coll = @coll.sort_by_co2
    coll.inspect.should eql "[electricity : [\"Argentina\",500,240], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",1234,600]]"
    @coll.inspect.should eql "[electricity : [\"Argentina\",1234,600], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",500,240]]"
    coll = @coll.sort_by_usage
    coll.inspect.should eql "[electricity : [\"Argentina\",500,240], electricity : [\"Argentina\",1000,480], electricity : [\"Argentina\",1234,600]]"
  end

  it "should standardize units in place" do
    @coll.first['usage'].unit 'J'
    @coll.first['usage'].value.should eql 500
    @coll.first['usage'].unit.label.should eql 'J'
    @coll.standardize_units!(:usage,:kWh)
    @coll.first['usage'].unit 'kWh'
    @coll.first['usage'].value.should be_close 0.000138888888888889,0.000001
  end

  it "should standardize units returning new collection" do
    @coll.first['co2'].value.should eql 240
    @coll.first['co2'].unit.label.should eql 't'
    coll = @coll.standardize_units(:co2,:lb)
    coll.first['co2'].unit 'lb'
    coll.first['co2'].value.should be_close 529109.429243706,0.01
  end

  it "should handle 'type' as a terms filter" do
    calcs = []
    calcs << add_transport_calc(500,240)
    calcs << add_transport_calc(1000,480)
    calcs << add_transport_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @coll.each { |calc| calc['type'].value "car" }
    terms = @coll.type
    terms.should be_a TermsList
    terms.values.all? {|val| val == "car"}.should be_true
  end
end

