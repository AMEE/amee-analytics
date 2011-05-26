module AMEE
  module DataAbstraction
    module CalculationCollectionReportingSupport

      def homogeneous?
        calculation_labels.size == 1
      end

      def heterogeneous?
        !homogeneous?
      end

      def calculation_labels
        map(&:label).uniq
      end

      def sort_by(term)
        term = term.to_sym unless term.is_a? Symbol
        CalculationCollection.new(send(term).sort_by(:value).map(&:parent))
      end

      def sort_by!(term)
        replace(sort_by(term))
      end

      def standardize_units(term,unit=nil,per_unit=nil)
        term = term.to_sym unless term.is_a? Symbol
        new_calcs = send(term).standardize_units(unit,per_unit).map do |term|
          calc = term.parent
          calc.contents[term.label] = term
          calc
        end
        CalculationCollection.new(new_calcs)
      end

      def standardize_units!(term,unit=nil,per_unit=nil)
        new_calcs = standardize_units(term,unit,per_unit)
        replace(new_calcs)
      end
      
      def calculate_all!
        each { |calc| calc.calculate! }
      end
      
      def save_all!
        each { |calc| calc.save }
      end

      def terms
        TermsList.new( (self.map { |calc| calc.terms.map { |term| term } }).flatten )
      end

      TermsList::Selectors.each do |sel|
        delegate sel,:to=>:terms
      end

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
