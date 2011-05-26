
module AMEE
  module DataAbstraction
    module TermsListReportingSupport

      # Do all terms represent the same thing?
      def analogous?
        labels.uniq.size == 1
      end

      # Do all terms represent the same thing AND contain consistent units?
      def homogeneous?
        analogous? and homogeneous_units? and homogeneous_per_units?
      end

      def heterogeneous?
        !homogeneous?
      end

      # Are all units the same?
      def homogeneous_units?
        return true if all? { |term| term.unit.nil? } or
          ( all? { |term| term.unit.is_a? Quantity::Unit::Base } and
            map { |term| term.unit.label }.uniq.size == 1 )
        return false
      end

      # Are all per units the same?
      def homogeneous_per_units?
        return true if all? { |term| term.per_unit.nil? } or
          ( all? { |term| term.per_unit.is_a? Quantity::Unit::Base } and
            map { |term| term.per_unit.label }.uniq.size == 1 )
        return false
      end
      
      def label
        first.label unless heterogeneous?
      end

      def numeric?
        all? { |term| term.value.is_a? Numeric }
      end

      def predominant_unit
        terms = reject { |term| term.unit.nil? }
        unit = terms.group_by { |term| term.unit.label }.
          max {|a,b| a.last.size <=> b.last.size }.first unless terms.blank?
        return unit
      end

      def predominant_per_unit
        terms = reject { |term| term.per_unit.nil? }
        unit = terms.group_by { |term| term.per_unit.label }.
          max {|a,b| a.last.size <=> b.last.size }.first unless terms.blank?
        return unit
      end

      def standardize_units(unit=nil,per_unit=nil)
        raise InvalidUnits, "#{self.class} contains multiple term types: #{labels.uniq.join(", ")}" unless analogous?
        return self if homogeneous? and ((unit.nil? or (first.unit and first.unit.label == unit)) and
           (per_unit.nil? or (first.per_unit and first.per_unit.label == per_unit)))
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        new_terms = map { |term| term.convert_unit(:unit => unit, :per_unit => per_unit) }
        TermsList.new new_terms
      end
      
      def sum(unit=nil,per_unit=nil)
        return nil unless numeric?
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        value = standardize_units(unit,per_unit).inject(0.0) do |sum,term|
          sum + term.value
        end
        initialize_result(label,value,unit,per_unit)
      end
      
      def mean(unit=nil,per_unit=nil)
        return nil unless numeric?
        sum = sum(unit,per_unit)
        initialize_result(sum.label,(sum.value/size),sum.unit,sum.per_unit)
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
          return nil
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
        sort! { |term,other_term| term.send(attr) <=> other_term.send(attr) }
      end

      def sort_by(attr)
        sort { |term,other_term| term.send(attr) <=> other_term.send(attr) }
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
