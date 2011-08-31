== amee-analytics

The amee-analytics gem provides support for handling collections of the class
<i>AMEE::DataAbstraction::OngoingCalculation</i> and performing analytical
operations across the collection.

Licensed under the BSD 3-Clause license (See LICENSE.txt for details)

Authors: James Smith, Andrew Berkeley, George Palmer

Copyright: Copyright (c) 2011 AMEE UK Ltd

Homepage: http://github.com/AMEE/amee-analytics

Documentation: http://rubydoc.info/gems/amee-analytics

== INSTALLATION

 gem install amee-analytics

== REQUIREMENTS

 * ruby 1.8.7
 * rubygems >= 1.5

 All gem requirements should be installed as part of the rubygems installation process
 above, but are listed here for completeness.

 * amee-data-abstraction ~> 1.1
 * amee-data-persistence ~> 1.1
 
== USAGE

The library extends a number of classes within the <i>AMEE::DataAbstraction</i>
module:

1. <i>AMEE::DataAbstraction::CalculationCollection</i> is extended by the
<i>CalculationCollectionReportingSupport</i> module, providing the ability to filter
specific calculation terms, sort by term values, standardize units and perform
analytical operations on specific terms, such as sums, means, modes, and medians

2. <i>AMEE::DataAbstraction::TermsList</i> is extended by the
<i>TermsListReportingSupport</i> module. This provides much of the functionality
used by <i>CalculationCollectionReportingSupport</i>, allowing lists to be sorted
and summed, averaged, etc...

3. <i>AMEE::DataAbstraction::Term</i> is extended by the <i>TermReportingSupport</i>
module. This provides the ability to convert the units within a term (changing the
term value attribute accordingly), and is used by the operations provided in
<i>CalculationCollectionReportingSupport</i> and <i>TermsListReportingSupport</i>.

4. A new subclass of <i>AMEE::DataAbstraction::Term</i> is defined, <i>Result</i>.
This provides a simple container for returning the result of a <i>TermsList</i>
analytical operation (e.g. sum, mean) complete with label, value, unit, etc...

=Example usage

  # find method returns instance of CalculationCollection
  my_calculations = OngoingCalculation.find_by_type(:all, :electricity)
    #=> <AMEE::DataAbstraction::CalculationCollection ... >

  # Dynamic label-derived method returns TermsList of the named term from each
  # calculation in the set

  my_calculations.country #=> <AMEE::DataAbstraction::TermsList ... >

  my_calculations.energy #=> <AMEE::DataAbstraction::TermsList ... >

  my_calculations.co2 #=> <AMEE::DataAbstraction::TermsList ... >

  # Analytical operations can be applied to lists of terms. These return new
  # objects, of the Result class. #to_s used here for illustrative purposes

  my_calculations.country.sum.to_s #=> "0.0"

  my_calculations.energy.sum.to_s #=> "23456 kWh"

  my_calculations.co2.sum.to_s #=> "12345 kg"

  my_calculations.co2.sum(:lb).to_s #=> "23456 lb"

  my_calculations.country.mode.to_s #=> "Sweden"

  my_calculations.co2.mean.to_s #=> "4512.5 kg"

  my_calculations.co2.mean('t').to_s #=> "4.5125 t"

  my_calculations.co2.median.to_s #=> "4567 kg"

  my_calculations.co2.predominant_unit #=> "kg"

  my_calculations.sort_by_co2 #=> <AMEE::DataAbstraction::CalculationCollection ... >

  my_calculations.sort_by_co2! #=> <AMEE::DataAbstraction::CalculationCollection ... >