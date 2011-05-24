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

  
end

