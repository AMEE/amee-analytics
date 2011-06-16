
module AMEE
  module DataAbstraction
    module TermsListReportingSupport

      # Returns true if all terms within the list have the same label. This enables
      # a check as to whether all terms represent the same thing, i.e. same calculation
      # component (i.e. the same drill choice, or profile item value, or return value, or
      # metadata type).
      #
      def analogous?
        labels.uniq.size == (1 or nil)
      end

      # Returns true if all terms within the list have the same label AND contain
      # consistent units. This enables a term list to be manipulated numerically,
      # for example, by producing a sum or a mean across all terms.
      #
      def homogeneous?
        analogous? and homogeneous_units? and homogeneous_per_units?
      end

      # Returns true if TermsList is not homogeneous, i.e. it does not contain all
      # analogous terms with corrosponding units.
      #
      def heterogeneous?
        !homogeneous?
      end

      # Returns true if all terms within the list are represented by the same
      # unit or are all nil.
      #
      def homogeneous_units?
        return true if all? { |term| term.unit.nil? } or
          ( all? { |term| term.unit.is_a? Quantity::Unit::Base } and
            map { |term| term.unit.label }.uniq.size == 1 )
        return false
      end

      # Returns true if all terms within the list are represented by the same
      # per unit or all per units are all nil.
      #
      def homogeneous_per_units?
        return true if all? { |term| term.per_unit.nil? } or
          ( all? { |term| term.per_unit.is_a? Quantity::Unit::Base } and
            map { |term| term.per_unit.label }.uniq.size == 1 )
        return false
      end

      # Returns the label which defines all terms in the terms list if they are
      # all the same
      #
      def label
        first.label unless heterogeneous?
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

      # Returns true if all terms in the list have numeric values
      def all_numeric?
        all? { |term| term.has_numeric_value? }
      end

      # Returns a new list comprising only those terms which have numeric values.
      # This is useful for establishing which terms in a list to operate numerically
      # on
      def numeric_terms
        TermsList.new select { |term| term.has_numeric_value? }
      end

      # Returns a new terms list with all units standardized and the respective term
      # values adjusted accordingly. The unit and per units to be standardized to
      # can be specified as the first and second arguments. Either the unit name,
      # symbol or label (as defined in the Quantify gem) can be used. If no arguments
      # are specified, the standardized units represent those which are predominant in the
      # list, e.g.
      #
      #   list.standardize_units                  #=> <TermsList>
      #
      #   list.standardize_units(:t,:kWh)         #=> <TermsList>
      #
      #   list.standardize_units('pound')         #=> <TermsList>
      #
      def standardize_units(unit=nil,per_unit=nil)
        return self if homogeneous? and ((unit.nil? or (first.unit and first.unit.label == unit)) and
           (per_unit.nil? or (first.per_unit and first.per_unit.label == per_unit)))
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        new_terms = map { |term| term.convert_unit(:unit => unit, :per_unit => per_unit) }
        TermsList.new new_terms
      end

      # Returns a new Result object which represents the sum of all term values
      # within the list
      def sum(unit=nil,per_unit=nil)
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        value = numeric_terms.standardize_units(unit,per_unit).inject(0.0) do |sum,term|
          sum + term.value
        end
        initialize_result(label,value,unit,per_unit)
      end
      
      def mean(unit=nil,per_unit=nil)
        list = numeric_terms
        sum = list.sum(unit,per_unit)
        initialize_result(sum.label,(sum.value/list.size),sum.unit,sum.per_unit)
      end

      # Return the most prevalent value for the list, i.e. the modal value.
      def mode
        groups = standardize_units.reject { |term| term.value.nil? }.
          group_by { |term| term.value }.map(&:last)
        max_group_size = groups.max {|a,b| a.size <=> b.size }.size
        max_groups = groups.select {|a| a.size == max_group_size}
        if max_groups.size == 1
          initialize_result_from_term(max_groups.first.first)
        else
          TermsList.new max_groups.map { |group| initialize_result_from_term(group.first) }
        end
      end
      
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
        initialize_result_from_term(median_term)
      end

      def initialize_result_from_term(term)
        result_term = Result.new
        TermsList::TermProperties.each do |attr|
          result_term.send(attr, term.send(attr))
        end
        return result_term
      end

      def initialize_result(label,value,unit=nil,per_unit=nil,options={})
        Result.new { label label; value value; unit unit; per_unit per_unit }
      end

      def sort_by!(attr)
        replace(sort_by(attr))
      end

      # Remove unset terms before sort and append at end
      def sort_by(attr)
        unset_terms = select { |term| term.unset? }
        set_terms = select { |term| term.set? }
        set_terms.sort! { |term,other_term| term.send(attr) <=> other_term.send(attr) }
        TermsList.new(set_terms + unset_terms)
      end

      # We want to be be able to dynamically retrieve subsets of terms via their
      # labels. This is enabled by the first #method_missing method. However, #type
      # (which is a common path in AMEE categories) is a special case in ruby and
      # returns the class of the receiver (although this is deprecated). Therefore,
      # this method overrides that behaviour for the TermsList class only
      #
      def type
        TermsList.new select{ |x| x.label == :type }
      end
      
      def method_missing(method, *args, &block)
        if labels.include? method
          TermsList.new select{ |x| x.label == method }
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
