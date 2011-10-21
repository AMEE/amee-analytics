
# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.
# 
# :title: Module: AMEE::DataAbstraction::TermsListAnalyticsSupport

module AMEE
  module Analytics

    # Mixin module for the <i>AMEE::DataAbstraction::Term</i> class, providing
    # methods for handling collections of calculations.
    #
    module TermsListAnalyticsSupport
      
      def name
        first.name if analogous?
      end

      # Returns <tt>true</tt> if all terms within the list have the same label.
      # Otherwise, returns <tt>false</tt>.
      # 
      # This enables a check as to whether all terms represent the same thing,
      # i.e. same calculation component (i.e. the same drill choice, or profile
      # item value, or return value, or metadata type).
      #
      def analogous?
        labels.uniq.size == (1 or nil)
      end

      # Returns <tt>true</tt> if all terms within the list have the same label
      # AND contain consistent units. Otherwise, returns <tt>false</tt>.
      # 
      # This enables a term list to be manipulated numerically, for example, by
      # producing a sum or a mean across all terms.
      #
      def homogeneous?
        analogous? and homogeneous_units? and homogeneous_per_units?
      end

      # Returns <tt>true</tt> if TermsList is NOT homogeneous, i.e. it does NOT
      # contain all analogous terms with corresponding units. Otherwise, returns
      # <tt>false</tt>.
      #
      def heterogeneous?
        !homogeneous?
      end

      # Returns <tt>true</tt> if all terms within the list are represented by the
      # same unit or are all <tt>nil</tt>. Otherwise, returns <tt>false</tt>.
      #
      def homogeneous_units?
        return true if all? { |term| term.unit.nil? } or
          ( all? { |term| term.unit.is_a? Quantity::Unit::Base } and
            map { |term| term.unit.label }.uniq.size == 1 )
        return false
      end

      # Returns <tt>true</tt> if all terms within the list are represented by the
      # same PER unit or are all <tt>nil</tt>. Otherwise, returns <tt>false</tt>.
      #
      def homogeneous_per_units?
        return true if all? { |term| term.per_unit.nil? } or
          ( all? { |term| term.per_unit.is_a? Quantity::Unit::Base } and
            map { |term| term.per_unit.label }.uniq.size == 1 )
        return false
      end

      # Returns the label which defines all terms in contained within <tt>self</tt>,
      # if they are all the same. Otherwise, returns <tt>nil</tt>.
      #
      def label
        first.label if analogous?
      end

      def +(other_list)
        self.class.new(self.to_a + other_list.to_a)
      end

      def -(other_list)
        other_list = [other_list].flatten
        self.delete_if { |term| other_list.include?(term) }
      end

      def first_of_each_type
        labels = self.labels.uniq
        terms = labels.map {|label| find { |term| term.label == label } }
        AMEE::DataAbstraction::TermsList.new(terms)
      end

      # Returns the label of the unit which is predominantly used across all terms
      # in the list, e.g.
      #
      #  list.predominant_unit      #=> kg
      #
      #  list.predominant_unit      #=> kWh
      #
      # Returns nil if all units are blank
      #
      def predominant_unit
        terms = reject { |term| term.unit.nil? }
        unit = terms.group_by { |term| term.unit.label }.
          max {|a,b| a.last.size <=> b.last.size }.first unless terms.blank?
        return unit
      end

      # Returns the label of the per unit which is predominantly used across all terms
      # in the list, e.g.
      #
      #  list.predominant_per_unit      #=> h
      #
      #  list.predominant_per_unit      #=> kWh
      #
      # Returns nil if all per units are blank
      #
      def predominant_per_unit
        terms = reject { |term| term.per_unit.nil? }
        unit = terms.group_by { |term| term.per_unit.label }.
          max {|a,b| a.last.size <=> b.last.size }.first unless terms.blank?
        return unit
      end

      # Returns <tt>true</tt> if all terms in the list have numeric values.
      # Otherwise, returns <tt>false</tt>.
      #
      def all_numeric?
        all? { |term| term.has_numeric_value? }
      end

      # Returns a new instance of <i>TermsList</i> comprising only those terms
      # belongong to <tt>self</tt> which have numeric values.
      #
      # This is useful for establishing which terms in a list to perform numerical
      # operations on
      #
      def numeric_terms
        AMEE::DataAbstraction::TermsList.new select { |term| term.has_numeric_value? }
      end

      # Returns a new instance of <i>TermsList</i> with all units standardized and
      # the respective term values adjusted accordingly.
      # 
      # The unit and per units to be standardized to can be specified as the first
      # and second arguments respectively. Either the unit name, symbol or label
      # (as defined in the <i>Quantify</i> gem) can be used. If no arguments are
      # specified, the standardized units represent those which are predominant
      # in the list, e.g.
      #
      #   list.standardize_units                  #=> <TermsList>
      #
      #   list.standardize_units(:t,:kWh)         #=> <TermsList>
      #
      #   list.standardize_units('pound')         #=> <TermsList>
      #
      #   list.standardize_units(nil, 'BTU')      #=> <TermsList>
      #
      def standardize_units(unit=nil,per_unit=nil)
        return self if homogeneous? and ((unit.nil? or (first.unit and first.unit.label == unit)) and
           (per_unit.nil? or (first.per_unit and first.per_unit.label == per_unit)))
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        new_terms = map { |term| term.convert_unit(:unit => unit, :per_unit => per_unit) }
        AMEE::DataAbstraction::TermsList.new new_terms
      end

      # Returns a new instance of <i>Result</i> which represents the sum of all
      # term values within the list.
      #
      # Any terms within self which contain non-numeric values are ignored.
      #
      # If the terms within <tt>self</tt> do not contain consistent units, they
      # are standardized by default to the unit (and per unit) which predominate
      # in the list. Alternatively, the required unit and per units can be
      # specified as arguments using the same conventions as the
      # <tt>#standardize_units</tt> method.
      #
      def sum(unit=nil,per_unit=nil)
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        value = numeric_terms.standardize_units(unit,per_unit).inject(0.0) do |sum,term|
          sum + term.value
        end
        template = self
        Result.new { label template.label; value value; unit unit; per_unit per_unit; name template.name }
      end

      # Returns a new instance of <i>Result</i> which represents the mean of all
      # term values within the list.
      #
      # Any terms within self which contain non-numeric values are ignored.
      #
      # If the terms within <tt>self</tt> do not contain consistent units, they
      # are standardized by default to the unit (and per unit) which predominate
      # in the list. Alternatively, the required unit and per units can be
      # specified as arguments using the same conventions as the
      # <tt>#standardize_units</tt> method.
      #
      def mean(unit=nil,per_unit=nil)
        list = numeric_terms
        sum = list.sum(unit,per_unit)
        Result.new { label sum.label; value (sum.value/list.size); unit sum.unit; per_unit sum.per_unit; name sum.name }
      end

      # Returns a representation of the term with most prevalent value in
      # <tt>self</tt>, i.e. the modal value. This method considers both numerical
      # and text values.
      #
      # If only a single modal value is discovered an instance of the class
      # <i>Result</i> is returning representing the modal value. Where multiple
      # modal values occur a new instance of <i>TermsList</i> is returned
      # containing <i>Result</i> representations of each modal value.
      #
      def mode
        groups = standardize_units.reject { |term| term.value.nil? }.
          group_by { |term| term.value }.map(&:last)
        max_group_size = groups.max {|a,b| a.size <=> b.size }.size
        max_groups = groups.select {|a| a.size == max_group_size}
        if max_groups.size == 1
          max_groups.first.first.to_result
        else
          AMEE::DataAbstraction::TermsList.new max_groups.map { |group| group.first.to_result }
        end
      end

      # Returns a representation of the term with median value in <tt>self</tt>.
      # This method considers both numerical and text values.
      #
      # If <tt>self</tt> has an even-numbered size, the median is caluclated as
      # the mean of the values of the two centrally placed terms (having been
      # sorted according to their value attributes).
      #
      def median
        new_list = standardize_units
        midpoint = new_list.size/2
        if new_list.size % 2.0 == 1
          median_term = new_list.sort_by_value[midpoint]
        elsif new_list.size % 2.0 == 0
          median_term = new_list.sort_by_value[midpoint-1, 2].mean
        else
          raise
        end
        median_term.to_result
      end

      # Convenience method for initializing instances of the <i>Result</i> class.
      # Intialize the new object with the attributes described by <tt>label</tt>,
      # <tt>value</tt>, <tt>unit</tt> and <tt>per_unit</tt>. The unit and per_unit
      # attributes default to <tt>nil</tt> if left unspecified.
      #
      def initialize_result(label,value,unit=nil,per_unit=nil)
        Result.new { label label; value value; unit unit; per_unit per_unit }
      end

      # Move an individual term to a specified location (index) within the list.
      # The specific term is selected on the basis of one of it's attributes values,
      # with the attribute to use (e.g. :value, :unit) given by <tt>attr</attr>
      # and value by <tt>value</tt>. The location within the list to move the term
      # is given as an index integer value as the final argument.
      #
      def move_by(attr,value,index)
        if attr == :unit || attr == :per_unit
          value = Unit.for value
        end
        term = find {|t| t.send(attr) == value }
        return if term.nil?
        delete(term)
        insert(index, term)
      end

      # Rotate the list terms by one element - shifts the first-placed term to the
      # end of the list, advancing all terms forward by one place.
      def rotate
        push(self.shift)
      end

      # Sorts the terms list in place according to the term attribute indicated by
      # <tt>attr</tt>, returning <tt>self</tt>.
      #
      # If differences in units exist between terms, sorting occur based on the
      # absolute quantities implied.
      #
      #   my_terms_list.sort_by! :value
      #
      #                   #=> <AMEE::DataAbstraction::TermsList ... >
      #
      def sort_by!(attr)
        replace(sort_by(attr))
      end

      # Similar to <tt>#sort_by!</tt> but returns a new instance of
      # <i>TermsList</i> arranged according to the values on the
      # attribute <tt>attr</tt>.
      #
      #
      # If differences in units exist between terms, sorting occur based on the
      # absolute quantities implied.
      #
      # E.g.
      #
      #   my_terms_list.sort_by :value
      #
      #                   #=> <AMEE::DataAbstraction::TermsList ... >
      #
      def sort_by(attr)
        # 1. Remove unset terms before sort and append at end
        #
        # 2. Establish set terms
        #
        # 3. Zip together with corresponding standardized units list creating a
        # list of Term pairs
        #
        # 4. Sort list according to standardized Terms
        #
        # 5. Return map of original (now sorted) Terms

        unset_terms, set_terms = self.partition { |term| term.unset? || term.value.nil? }
        standardized_set_terms = AMEE::DataAbstraction::TermsList.new(set_terms).standardize_units
        ordered_set_terms = set_terms.zip(standardized_set_terms).sort! do |term,other_term|
          term[1].send(attr) <=> other_term[1].send(attr)
        end.map {|term_array| term_array[0]}
        AMEE::DataAbstraction::TermsList.new(ordered_set_terms + unset_terms)
      end

      # Return an instance of <i>TermsList</i> containing only terms labelled
      # :type.
      #
      # This method overrides the standard #type method (which is deprecated) and
      # mimics the functionality provied by the first #method_missing method in
      # dynamically retrieving a subset of terms according their labels.
      #
      def type
        AMEE::DataAbstraction::TermsList.new select{ |x| x.label == :type }
      end

      def respond_to?(method)
        if labels.include? method.to_sym
          return true
        elsif method.to_s =~ /sort_by_(.*)!/ and self.class::TermProperties.include? $1.to_sym
          return true
        elsif method.to_s =~ /sort_by_(.*)/ and self.class::TermProperties.include? $1.to_sym
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
      # contained within <tt>self</tt> and return a new instance of the
      # <tt>TermsList</tt> class containing each of those terms. E.g.,
      #
      #   my_terms = my_terms_list.type              #=> <AMEE::DataAbstraction::TermsList>
      #   my_terms.label                             #=> :type
      #
      #   my_terms = my_terms_list.mass              #=> <AMEE::DataAbstraction::TermsList>
      #   my_terms.label                             #=> :mass
      #
      #   my_terms = my_terms_list.co2               #=> <AMEE::DataAbstraction::TermsList>
      #   my_terms.label                             #=> :co2
      #
      # ---
      #
      # Call either the <tt>#sort_by</tt> or <tt>#sort_by!</tt> methods including
      # the argument term as part of the method name, e.g.,
      #
      #   my_calculation_collection.sort_by_value
      #
      #                   #=> <AMEE::DataAbstraction::TermsList ... >
      #
      #   my_calculation_collection.sort_by_name!
      #
      #                   #=> <AMEE::DataAbstraction::TermsList ... >
      #
      def method_missing(method, *args, &block)
        if labels.include? method
          AMEE::DataAbstraction::TermsList.new select{ |x| x.label == method }
        elsif method.to_s =~ /sort_by_(.*)!/ and self.class::TermProperties.include? $1.to_sym
          sort_by! $1.to_sym
        elsif method.to_s =~ /sort_by_(.*)/ and self.class::TermProperties.include? $1.to_sym
          sort_by $1.to_sym
        else
          super
        end
      end

    end
  end
end
