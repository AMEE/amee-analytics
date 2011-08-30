# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

# :title: Module: AMEE::DataAbstraction::CalculationCollectionAnalyticsSupport

module AMEE
  module DataAbstraction

    # Mixin module for the <i>AMEE::DataAbstraction::CalculationCollection</i>
    # class, providing methods for handling collections of calculations.
    #
    module CalculationCollectionAnalyticsSupport

      # Returns <tt>true</tt> if all calculations in <tt>self</tt> are
      # representatives of the same prototype calculation. Otherwise,
      # returns <tt>false</tt>.
      #
      def homogeneous?
        calculation_labels.size == 1
      end

      # Returns <tt>true</tt> if all calculations in <tt>self</tt> are NOT
      # representatives of the same prototype calculation. Otherwise,
      # returns <tt>false</tt>.
      #
      def heterogeneous?
        !homogeneous?
      end

      # Returns an array containing all of the unique labels for calculations
      # held in <tt>self</tt>.
      #
      def calculation_labels
        map(&:label).uniq
      end

      def +(other_calc_coll)
        self.class.new(self.to_a + other_calc_coll.to_a)
      end

      def -(other_calc_coll)
        other_calc_coll = [other_calc_coll].flatten
        self.delete_if { |calc| other_calc_coll.include?(calc) }
      end

      # Similar to <tt>#sort_by!</tt> but returns a new instance of
      # <i>CalculationCollection</i> arranged according to the values on the
      # term labelled <tt>term</tt>. E.g.
      #
      #   my_calculation_collection.sort_by :co2
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      def sort_by(term)
        term = term.to_sym unless term.is_a? Symbol
        CalculationCollection.new(send(term).sort_by(:value).map(&:parent))
      end

      # Sorts the calculation collection in place according to the values on the
      # term labelled <tt>term</tt>, returning <tt>self</tt>.
      #
      #   my_calculation_collection.sort_by! :mass
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      def sort_by!(term)
        replace(sort_by(term))
      end

      # Returns a new instance of <i>CalculationCollection</i> containing the same
      # calculations contained within <tt>self</tt> but with the units of the term
      # <tt>term</tt> standardized on each.
      #
      # If no further arguments are provided, the standardized units represent
      # those which currently predominate amongst the relevent terms. Otherwise,
      # the specific unit and/or per unit which are required for each instance
      # of <tt>term</tt> can be explicitly specified as the second and third
      # arguments respecitively. Units can be specified in any of the formats
      # which are acceptable to the <tt>Quantify::Unit.for</tt> method (i.e.
      # stringified unit names or symbols, symbolized labels, or
      # <tt>Quantify::Unit::Base</tt> instances of the required unit). E.g.
      #
      #   my_calculation_collection.standardize_units(:mass)
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      #   my_calculation_collection.standardize_units(:mass, :lb)
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      #   my_calculation_collection.standardize_units(:mass, 'pound')
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      #   my_calculation_collection.standardize_units(:mass, <Quantify::Unit::NonSI>)
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      #   my_calculation_collection.standardize_units(:distance, :km, 'year')
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      def standardize_units(term,unit=nil,per_unit=nil)
        term = term.to_sym unless term.is_a? Symbol
        new_calcs = send(term).standardize_units(unit,per_unit).map do |term|
          calc = term.parent
          calc.contents[term.label] = term
          calc
        end
        CalculationCollection.new(new_calcs)
      end

      # Similar to <tt>#standardize_units</tt> but standardizes units in place,
      # returning <tt>self</tt>
      #
      def standardize_units!(term,unit=nil,per_unit=nil)
        new_calcs = standardize_units(term,unit,per_unit)
        replace(new_calcs)
      end

      # Returns an array of instances of the <tt>Result</tt> class representing the
      # sums of all outputs represented within the collection
      #
      def sum_all_outputs
        TermsList.new(terms.outputs.visible.labels.uniq.map { |o| send(o).sum })
      end

      # Returns a new instance of the class <tt>TermsList</tt> representing either
      # CO2 or CO2e outputs from each calculation
      #
      def co2_or_co2e_outputs
        terms = TermsList.new
        each do |calculation|
          if calculation['co2e']
            terms << calculation['co2e']
          elsif calculation.outputs.visible.labels.size == 1 && calculation.outputs.visible.labels.first == :co2
            terms << calculation['co2']
          end
        end
        return terms
      end

      # Call the <tt>#calculate!</tt> method on all calculations contained within
      # <tt>self</tt>.
      #
      def calculate_all!
        each { |calc| calc.calculate! }
      end

      # Call the <tt>#save</tt> method on all calculations contained within
      # <tt>self</tt>.
      #
      def save_all!
        each { |calc| calc.save }
      end

      # Returns a terms list of all terms held by calculations contained within
      # <tt>self</tt>.
      #
      def terms
        TermsList.new( (self.map { |calc| calc.terms.map { |term| term } }).flatten )
      end

      TermsList::Selectors.each do |sel|
        delegate sel,:to=>:terms
      end

      # Return an instance of <i>TermsList</i> containing only terms labelled 
      # :type.
      # 
      # This method overrides the standard #type method (which is deprecated) and
      # mimics the functionality provied by the first #method_missing method in
      # dynamically retrieving a subset of terms according their labels.
      #
      def type
        terms.type
      end

      def respond_to?(method)
        if terms.labels.include? method.to_sym
          return true
        elsif method.to_s =~ /sort_by_(.*)!/ and terms.labels.include? $1.to_sym
          return true
        elsif method.to_s =~ /sort_by_(.*)/ and terms.labels.include? $1.to_sym
          return true
        else
          super
        end
      end

      # Syntactic sugar for several instance methods.
      #
      # ---
      #
      # Call a method on <tt>self</tt> which named after a specific term label
      # contained with an associated calculation and return an instance of the
      # <tt>TermsList</tt> class contain each of those terms. E.g.,
      #
      #   my_terms = my_calculation_collection.type  #=> <AMEE::DataAbstraction::TermsList>
      #   my_terms.label                             #=> :type
      #
      #   my_terms = my_calculation_collection.mass  #=> <AMEE::DataAbstraction::TermsList>
      #   my_terms.label                             #=> :mass
      #
      #   my_terms = my_calculation_collection.co2   #=> <AMEE::DataAbstraction::TermsList>
      #   my_terms.label                             #=> :co2
      #
      # ---
      #
      # Call either the <tt>#sort_by</tt> or <tt>#sort_by!</tt> methods including
      # the argument term as part of the method name, e.g.,
      #
      #   my_calculation_collection.sort_by_co2
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      #   my_calculation_collection.sort_by_mass!
      #
      #                   #=> <AMEE::DataAbstraction::CalculationCollection ... >
      #
      def method_missing(method, *args, &block)
        if terms.labels.include? method.to_sym
          terms.send(method.to_sym)
        elsif method.to_s =~ /sort_by_(.*)!/ and terms.labels.include? $1.to_sym
          sort_by! $1.to_sym
        elsif method.to_s =~ /sort_by_(.*)/ and terms.labels.include? $1.to_sym
          sort_by $1.to_sym
        else
          super
        end
      end

    end
    
  end
end