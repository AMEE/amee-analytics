require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

include AMEE::DataAbstraction

describe CalculationCollection do

  before(:each) do
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

  it "should be heterogeneous" do
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

  it "should sum term values with homogeneous calcs" do
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
    # check order
    @coll.first['co2'].value.should eql 240
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 600

    # reverse and check order
    @coll.reverse!
    @coll.first['co2'].value.should eql 600
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 240

    # sort by co2 and check order
    @coll.sort_by_co2!
    @coll.first['co2'].value.should eql 240
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 600

    # reverse and check order
    @coll.reverse!
    @coll.first['co2'].value.should eql 600
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 240

    # sort by usage and check order
    @coll.sort_by_usage!
    @coll.first['co2'].value.should eql 240
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 600
  end

  it "should sort by specified term and return new" do
    # check order
    @coll.first['co2'].value.should eql 240
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 600

    # reverse and check order
    @coll.reverse!
    @coll.first['co2'].value.should eql 600
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 240

    # instantiate new based on co2 and check order
    coll = @coll.sort_by_co2
    coll.first['co2'].value.should eql 240
    coll[1]['co2'].value.should eql 480
    coll.last['co2'].value.should eql 600

    # check reversed order of original
    @coll.first['co2'].value.should eql 600
    @coll[1]['co2'].value.should eql 480
    @coll.last['co2'].value.should eql 240

    # instantiate new based on usage and check order
    coll = @coll.sort_by_usage
    coll.first['co2'].value.should eql 240
    coll[1]['co2'].value.should eql 480
    coll.last['co2'].value.should eql 600
  end

  it "should sort calcs considering differences in units" do
    @coll.first['usage'].value.should eql 500
    @coll.first['usage'].unit.label.should eql 'kWh'
    @coll[1]['usage'].value.should eql 1000
    @coll[1]['usage'].unit.label.should eql 'kWh'
    @coll.last['usage'].unit 'J'
    @coll.last['usage'].value.should eql 1234
    @coll.last['usage'].unit.label.should eql 'J'
    @coll.sort_by_usage!
    @coll.first['usage'].value.should eql 1234
    @coll.first['usage'].unit.label.should eql 'J'
    @coll[1]['usage'].value.should eql 500
    @coll[1]['usage'].unit.label.should eql 'kWh'
    @coll.last['usage'].value.should eql 1000
    @coll.last['usage'].unit.label.should eql 'kWh'
  end

  it "should standardize units in place" do
    @coll.first['usage'].unit 'J'
    @coll.first['usage'].value.should eql 500
    @coll.first['usage'].unit.label.should eql 'J'
    @coll.standardize_units!(:usage,:kWh)
    @coll.first['usage'].unit 'kWh'
    @coll.first['usage'].value.should be_within(0.000001).of(0.000138888888888889)
  end

  it "should standardize units returning new collection" do
    @coll.first['co2'].value.should eql 240
    @coll.first['co2'].unit.label.should eql 't'
    coll = @coll.standardize_units(:co2,:lb)
    coll.first['co2'].unit 'lb'
    coll.first['co2'].value.should be_within(0.01).of(529109.429243706)
  end

  it "should standardize units in place and retain calcs missing term" do
    @coll.first['usage'].unit 'J'
    @coll.first['usage'].value.should eql 500
    @coll.first['usage'].unit.label.should eql 'J'
    pp @coll
    @coll[1].contents.delete(:usage)
    pp @coll
    @coll.size.should eql 3
    @coll.standardize_units!(:usage,:kWh)
    pp @coll
    @coll.first['usage'].unit 'kWh'
    @coll.first['usage'].value.should be_within(0.000001).of(0.000138888888888889)
    @coll[1].contents['usage'].should eql nil
    @coll.size.should eql 3
  end

  it "should standardize units returning new collection" do
    @coll.first['co2'].value.should eql 240
    @coll.first['co2'].unit.label.should eql 't'
    @coll[1].contents.delete(:co2)
    @coll.size.should eql 3
    coll = @coll.standardize_units(:co2,:lb)
    coll.first['co2'].unit 'lb'
    coll.first['co2'].value.should be_within(0.01).of(529109.429243706)
    coll[1].contents['co2'].should eql nil
    coll.size.should eql 3
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

  it "should add calculation collections" do
    calcs1 = []
    calcs1 << add_transport_calc(500,240)
    calcs1 << add_transport_calc(1000,480)
    calcs1 << add_transport_calc(1234,600)
    @coll1 = CalculationCollection.new(calcs1)
    calcs2 = []
    calcs2 << add_transport_calc(700,350)
    calcs2 << add_transport_calc(5,11)
    calcs2 << add_transport_calc(123,234)
    @coll2 = CalculationCollection.new(calcs2)
    @coll3 = @coll1 + @coll2
    @coll3.should be_a CalculationCollection
    @coll3.size.should eql 6
  end

  it "should subtract calculation collections" do
    calcs1 = []
    calcs1 << add_transport_calc(500,240)
    calcs1 << add_transport_calc(1000,480)
    calcs1 << add_transport_calc(1234,600)
    @coll1 = CalculationCollection.new(calcs1)
    calcs2 = []
    calcs2 << add_transport_calc(500,240)
    calcs2 << add_transport_calc(1000,480)
    @coll2 = CalculationCollection.new(calcs2)
    @coll3 = @coll1 - @coll2
    @coll3.should be_a CalculationCollection
    @coll3.size.should eql 1
    @coll3.first['distance'].value.should eql 1234
  end

  it "should add to calculation collection using += syntax" do
    @coll = CalculationCollection.new
    @coll += [add_transport_calc(500,240)]
    @coll.should be_a CalculationCollection
    @coll += [add_transport_calc(1000,480)]
    @coll.should be_a CalculationCollection
    @coll += [add_transport_calc(1234,600)]
    @coll.should be_a CalculationCollection
    @coll.size.should eql 3
  end

  it "should subtract from calculation collection using -= syntax" do
    calcs1 = []
    calcs1 << add_transport_calc(500,240)
    calcs1 << add_transport_calc(1000,480)
    calcs1 << add_transport_calc(1234,600)
    @coll1 = CalculationCollection.new(calcs1)
    @coll1 -= add_transport_calc(500,240)
    @coll1 -= add_transport_calc(1000,480)
    @coll1.should be_a CalculationCollection
    @coll1.size.should eql 1
    @coll1.first['distance'].value.should eql 1234
  end

  it "should add all outputs" do
    res = @coll.sum_all_outputs
    res.instance_of?(TermsList).should be_true
    res.first.value.should eql 1320.0
  end

  it "should respond to dynamic term methods" do
    @coll.respond_to?(:co2).should be_true
    @coll.respond_to?(:usage).should be_true
    @coll.respond_to?(:distance).should be_false
  end

  it "should respond to dynamic sort methods" do
    @coll.respond_to?(:sort_by_co2).should be_true
    @coll.respond_to?(:sort_by_usage!).should be_true
    @coll.respond_to?(:sort_by_distance).should be_false
  end

  it "should return co2 outputs" do
    terms = @coll.co2_or_co2e_outputs
    terms.size.should eql 3
    terms.first.label.should eql :co2
  end

end