require 'pp'
module AMEE
  module DataAbstraction
    module TermsListReportingSupport
      
      def analogous?
        map { |term| term.label }.uniq.size == 1
      end

      def homogeneous?
        analogous? and homogeneous_units? and homogeneous_per_units?
      end

      def heterogeneous?
        !homogeneous?
      end

      def homogeneous_units?
        return true if all? { |term| term.unit.nil? } or
          ( all? { |term| term.unit.is_a? Quantity::Unit::Base } and
            map { |term| term.unit.label }.uniq.size == 1 )
        return false
      end

      def homogeneous_per_units?
        return true if all? { |term| term.per_unit.nil? } or
          ( all? { |term| term.per_unit.is_a? Quantity::Unit::Base } and
            map { |term| term.per_unit.label }.uniq.size == 1 )
        return false
      end
      
      def label
        first.label unless heterogeneous?
      end

      def result(label,value,unit=nil,per_unit=nil)
        Result.new {
          label label
          value value
          unit unit
          per_unit per_unit
        }
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
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        new_terms = map do |term|
          term.convert_unit(:unit => unit, :per_unit => per_unit)
        end
        TermsList.new new_terms
      end
      
      def sum(unit=nil,per_unit=nil)
        return unless analogous?
        unit = predominant_unit if unit.nil?
        per_unit = predominant_per_unit if per_unit.nil?
        value = standardize_units(unit,per_unit).inject(0.0) do |sum,term|
          sum + term.value
        end
        result(label,value,unit,per_unit)
      end
      
      def mean(unit=nil,per_unit=nil)
        sum = sum(unit,per_unit)
        result(sum.label,(sum.value/size),sum.unit,sum.per_unit)
      end

      # Return the most prevalent value for the list, i.e. the modal value. This
      # method operates on the term value by default, but accepts alternative
      # attributes as a symbolized argument. This is useful, for example, for
      # discovering the predominant unit used in the list
      #
      def mode
        terms = reject { |term| term.value.nil? }
        modal_term = terms.group_by { |term| term.value }.
          max {|a,b| a.last.size <=> b.last.size }.first unless terms.blank?
        term_to_result(modal_term)
      end
      
      def median
        if size % 2.0 == 1
          midpoint = size/2
          median_term = sort_by_value[midpoint]
        elsif size % 2.0 == 0
          array = sort_by_value
          midpoint = size/2
          midpoints = [ array[midpoint-1], array[midpoint] ]
          median_term = midpoints.mean
        else
          raise
        end
        term_to_result(median_term)
      end

      def term_to_result(term)
        result(term.label,term.value,term.unit,term.per_unit)
      end
      
      def method_missing(method, *args, &block)
        if labels.include? method
          TermsList.new select{ |x| x.label == method }
        elsif method.to_s =~ /sort_by_(.*)!/ and self.class::TermProperties.include? $1.to_sym
          sort! { |term,other_term| term.send($1.to_sym) <=> other_term.send($1.to_sym) }
        elsif method.to_s =~ /sort_by_(.*)/ and self.class::TermProperties.include? $1.to_sym
          sort { |term,other_term| term.send($1.to_sym) <=> other_term.send($1.to_sym) }
        else
          super
        end
      end

    end
  end
end
