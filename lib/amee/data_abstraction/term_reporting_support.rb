
module AMEE
  module DataAbstraction
    module TermReportingSupport

      def convert_unit(options={})
        new = clone
        if options[:unit] and unit
          new_unit = Unit.for(options[:unit])
          Term.validate_dimensional_equivalence?(unit,new_unit)
          new.value Quantity.new(new.value,new.unit).to(new_unit).value
          new.unit options[:unit]
        end
        if options[:per_unit] and per_unit
          new_per_unit = Unit.for(options[:per_unit])
          Term.validate_dimensional_equivalence?(per_unit,new_per_unit)
          new.value Quantity.new(new.value,(1/new.per_unit)).to(Unit.for(new_per_unit)).value
          new.per_unit options[:per_unit]
        end
        return new
      end
     
    end
  end
end
