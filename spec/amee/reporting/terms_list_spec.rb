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

  it "full list should not be analogous" do
    # includes :usage AND :co2 terms
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
  
  it "should recognize non-consistent units" do
    @list.co2.first.unit 'lb'
    @list.co2[1].per_unit 'h'
    @list.co2.should be_analogous
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    @list.co2.should_not be_homogeneous_per_units
  end

  it "should raise error when standardizing units on non-analogous list" do
    lambda{@list.standardize_units}.should raise_error
  end

  it "should standardize term units with predominant units and convert values appropriately if no unit specified" do
    @list.co2.first.unit 'lb'
    @list.co2.first.value.should eql 240
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    list = @list.co2.standardize_units
    list.should be_homogeneous
    list.should be_homogeneous_units
    list.first.unit.label.should eql  't'
    list.first.value.should be_close 0.1088621688,0.001
  end

  it "should standardize term per units with predominant per units and convert values appropriately if no per unit specified" do
    @list.co2.each {|term| term.per_unit 'h'}
    @list.co2.first.per_unit 'min'
    @list.co2.first.value.should eql 240
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_per_units
    list = @list.co2.standardize_units
    list.should be_homogeneous
    list.should be_homogeneous_per_units
    list.first.per_unit.label.should eql  'h'
    list.first.value.should be_close 14400,0.001
  end

  it "should standardize term units AND per units with predominant units and convert values appropriately if no units specified" do
    @list.co2.each {|term| term.per_unit 'h'}
    @list.co2.first.per_unit 'min'
    @list.co2.first.unit 'lb'
    @list.co2.first.value.should eql 240
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    @list.co2.should_not be_homogeneous_per_units
    list = @list.co2.standardize_units
    list.should be_homogeneous
    list.should be_homogeneous_units
    list.should be_homogeneous_per_units
    list.first.unit.label.should eql 't'
    list.first.per_unit.label.should eql  'h'
    list.first.value.should be_close 6.531730128,0.001
  end

  it "should standardize term units with specfied units and convert values appropriately" do
    @list.co2.first.unit 'lb'
    @list.co2.first.value.should eql 240
    @list.co2[1].value.should eql 480
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    list = @list.co2.standardize_units(:lb)
    list.should be_homogeneous
    list.should be_homogeneous_units
    list.first.unit.label.should eql  'lb'
    list[1].unit.label.should eql  'lb'
    list.first.value.should eql 240.0
    list[1].value.should be_close 1058218.85848741,0.001
  end

  it "should standardize term per units with specfied per units and convert values appropriately" do
    @list.co2.each {|term| term.per_unit 'h'}
    @list.co2.first.per_unit 'min'
    @list.co2.first.value.should eql 240
    @list.co2[1].value.should eql 480
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_per_units
    list = @list.co2.standardize_units(nil,:min)
    list.should be_homogeneous
    list.should be_homogeneous_per_units
    list.first.per_unit.label.should eql 'min'
    list[1].per_unit.label.should eql  'min'
    list.first.value.should eql 240.0
    list[1].value.should be_close 8,0.001
  end

  it "should standardize term units AND per units with specfied units AND per units and convert values appropriately" do
    @list.co2.each {|term| term.per_unit 'h'}
    @list.co2.first.unit 'lb'
    @list.co2.first.per_unit 'min'
    @list.co2.first.value.should eql 240
    @list.co2[1].value.should eql 480
    @list.co2.should_not be_homogeneous
    @list.co2.should_not be_homogeneous_units
    @list.co2.should_not be_homogeneous_per_units
    list = @list.co2.standardize_units(:lb,:min)
    list.should be_homogeneous
    list.should be_homogeneous_units
    list.should be_homogeneous_per_units
    list.first.unit.label.should eql 'lb'
    list.first.per_unit.label.should eql 'min'
    list[1].unit.label.should eql 'lb'
    list[1].per_unit.label.should eql  'min'
    list.first.value.should eql 240.0
    list[1].value.should be_close 17636.9809747902,0.001
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

  it "should return 0.0 if no numerical term values found" do
    @list.country.sum.to_s.should eql "0.0"
  end

  it "should average terms" do
    @list.co2.mean.to_s.should eql "440.0 t"
  end

  it "should recognize numeric terms" do
    @list.should_not be_all_numeric
    @list.co2.should be_all_numeric
    @list.usage.should be_all_numeric
    @list.country.should_not be_all_numeric
  end

  it "should return median of numeric list" do
    @list.co2.median.to_s.should eql "480.0 t"
  end

  it "should return median of numeric list" do
    @list.usage.median.to_s.should eql "1000.0 kWh"
  end

  it "should return median of non-numeric list" do
    calcs = []
    calcs << add_transport_calc(500,240)
    calcs << add_transport_calc(1000,480)
    calcs << add_transport_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list = @coll.terms.type
    @list.each {|term| term.value "car"}
    @list.median.to_s.should eql "car"
    @list.first.value "van"
    @list[1].value "motorbike"
    @list.last.value "lorry"
    @list.median.to_s.should eql "motorbike"
  end

  it "should return mode of non numeric list" do
    calcs = []
    calcs << add_transport_calc(500,240)
    calcs << add_transport_calc(1000,480)
    calcs << add_transport_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list = @coll.terms.type
    @list.each {|term| term.value "car"}
    @list.mode.to_s.should eql "car"
    @list.first.value "van"
    @list[1].value "van"
    @list.last.value "lorry"
    @list.mode.to_s.should eql "van"
  end

  it "should return a TermsList for mode of list with some equal frequencies" do
    calcs = []
    calcs << add_transport_calc(500,240)
    calcs << add_transport_calc(1000,480)
    calcs << add_transport_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list = @coll.terms.type
    @list.each {|term| term.value "car"}
    @list.mode.to_s.should eql "car"
    @list.first.value "van"
    @list[1].value "motorbike"
    @list.last.value "lorry"
    @list.mode.should be_a TermsList
    @list.mode.size.should eql 3
  end

  it "should return mode of numeric list" do
    @list.usage.first.value 1000
    @list.usage.mode.to_s.should eql "1000.0 kWh"
  end

  it "should discover predominant unit" do
    @list.co2.predominant_unit.should eql 't'
    @list.usage.predominant_unit.should eql 'kWh'
    @list.co2.first.unit 'kg'
    @list.co2.predominant_unit.should eql 't'
    @list.co2.last.unit 'kg'
    @list.co2.predominant_unit.should eql 'kg'
  end

  it "should discover predominant per unit" do
    @list.co2.each {|term| term.per_unit 'h'}
    @list.usage.each {|term| term.per_unit 'm^2'}
    @list.co2.predominant_per_unit.should eql 'h'
    @list.usage.predominant_per_unit.should eql 'm²'
    @list.co2.first.per_unit 'min'
    @list.co2.predominant_per_unit.should eql 'h'
    @list.co2.last.per_unit 'min'
    @list.co2.predominant_per_unit.should eql 'min'
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

  it "should sort by value even if nil values present" do
    calcs = []
    calcs << add_transport_calc(500,240)
    calcs << add_transport_calc(1000,480)
    calcs << add_transport_calc(nil,nil)
    calcs << add_transport_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list = @coll.co2
    @list.first.value.should eql 240
    @list[1].value.should eql 480
    @list[2].value.should eql nil
    @list.last.value.should eql 600
    @list.reverse!
    @list.first.value.should_not eql 240
    @list.last.value.should_not eql 600
    @list.sort_by_value!
    @list.first.value.should eql 240
    @list[1].value.should eql 480
    @list[2].value.should eql 600
    @list.last.value.should eql nil
  end

  it "should return self on sort if all nil values present" do
    calcs = []
    calcs << add_transport_calc(nil,nil)
    calcs << add_transport_calc(nil,nil)
    calcs << add_transport_calc(nil,nil)
    calcs << add_transport_calc(nil,nil)
    @coll = CalculationCollection.new calcs
    @list = @coll.co2
    @list.first.value.should eql nil
    @list[1].value.should eql nil
    @list[2].value.should eql nil
    @list.last.value.should eql nil
    @list.reverse!
    @list.first.value.should eql nil
    @list.last.value.should eql nil
    @list.sort_by_value!
    @list.first.value.should eql nil
    @list[1].value.should eql nil
    @list[2].value.should eql nil
    @list.last.value.should eql nil
  end

  it "should return a new TermList for numeric only terms" do
    @list=@list.co2.numeric_terms.should be_a TermsList
  end

  it "should add TermsLists" do
    calcs = []
    calcs << add_elec_calc(500,240)
    calcs << add_elec_calc(1000,480)
    calcs << add_elec_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list1 = @coll.usage
    @list1.should be_a TermsList
    @list1.size.should eql 3
    @list2 = @coll.co2
    @list2.should be_a TermsList
    @list2.size.should eql 3
    @list3 = @list1 + @list2
    @list3.should be_a TermsList
    @list3.size.should eql 6
  end

  it "should subtract TermsLists" do
    calcs = []
    calcs << add_elec_calc(500,240)
    calcs << add_elec_calc(1000,480)
    calcs << add_elec_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list1 = @coll.usage
    @list1.should be_a TermsList
    @list1.size.should eql 3
    calcs = []
    calcs << add_elec_calc(1234,600)
    @coll = CalculationCollection.new calcs
    @list2 = @coll.usage
    @list2.should be_a TermsList
    @list2.size.should eql 1
    @list3 = @list1 - @list2
    @list3.should be_a TermsList
    @list3.size.should eql 2
  end

  it "should add to TermsList using += syntax" do
    @coll = CalculationCollection.new
    @coll << add_transport_calc(500,240)
    @list = TermsList.new
    @list.should be_a TermsList
    @list.size.should eql 0
    @list += @coll.distance
    @list.should be_a TermsList
    @list.size.should eql 1
    @list += @coll.co2
    @list.should be_a TermsList
    @list.size.should eql 2
  end

  it "should subtract from calculation collection using -= syntax" do
    @coll = CalculationCollection.new
    calc = add_transport_calc(500,240)
    @list = TermsList.new
    @list.should be_a TermsList
    @list.size.should eql 0
    @list += calc.terms
    @list.size.should eql 5
    @list -= calc['distance']
    @list.should be_a TermsList
    @list.size.should eql 4
    @list -= calc['co2']
    @list.should be_a TermsList
    @list.size.should eql 3
  end

  it "should return representations of each unique term" do
    terms = @coll.terms.uniq
    terms.should be_a TermsList
    terms.size.should eql 3
    terms.labels.map(&:to_s).sort.should eql ['co2','country','usage']
  end

  it "should respond to dynamic term methods" do
    @coll.terms.respond_to?(:co2).should be_true
    @coll.terms.respond_to?(:usage).should be_true
    @coll.terms.respond_to?(:distance).should be_false
  end

  it "should respond to dynamic sort methods" do
    @coll.terms.respond_to?(:sort_by_value).should be_true
    @coll.terms.respond_to?(:sort_by_unit!).should be_true
    @coll.terms.respond_to?(:sort_by_volume).should be_false
  end

end

