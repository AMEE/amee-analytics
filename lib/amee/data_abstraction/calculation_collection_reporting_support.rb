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

      def terms
        TermsList.new( (self.map { |calc| calc.terms.map { |term| term } }).flatten )
      end

      TermsList::Selectors.each do |sel|
        delegate sel,:to=>:terms
      end

      def method_missing(method, *args, &block)
        if terms.labels.include? method.to_sym
          terms.send(method.to_sym)
        else
          super
        end
      end

    end
    
  end
end
