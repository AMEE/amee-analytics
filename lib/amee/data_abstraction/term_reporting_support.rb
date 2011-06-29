#
# Authors::   James Hetherington, James Smith, Andrew Berkeley, George Palmer
# Copyright:: Copyright (c) 2011 AMEE UK Ltd
# License::   Permission is hereby granted, free of charge, to any person obtaining
#             a copy of this software and associated documentation files (the
#             "Software"), to deal in the Software without restriction, including
#             without limitation the rights to use, copy, modify, merge, publish,
#             distribute, sublicense, and/or sell copies of the Software, and to
#             permit persons to whom the Software is furnished to do so, subject
#             to the following conditions:
#
#             The above copyright notice and this permission notice shall be included
#             in all copies or substantial portions of the Software.
#
#             THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#             EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#             MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#             IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#             CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#             TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#             SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# :title: Module: AMEE::DataAbstraction::TermReportingSupport

module AMEE
  module DataAbstraction
    # Mixin module for the <i>AMEE::DataAbstraction::Term</i> class, providing
    # methods for handling collections of calculations.
    #
    module TermReportingSupport

      # Return a new instance of <i>Term</i>, based on <tt>self</tt> but with
      # a change of units, according to the <tt>options</tt> hash provided, and
      # the value attribute updated to reflect the new units.
      #
      # To specify a new unit, pass the required unit via the <tt>:unit</tt> key.
      # To specify a new per_unit, pass the required per unit via the
      # <tt>:per_unit</tt> key. E.g.,
      #
      #   my_term.convert_unit :unit => :kg
      #
      #   my_term.convert_unit :unit => :kg, per_unit => :h
      #
      #   my_term.convert_unit :unit => 'kilogram'
      #
      #   my_term.convert_unit :unit => Unit.kg
      #
      #   my_term.convert_unit :unit => <Quantify::Unit::SI ... >
      #
      # If <tt>self</tt> does not hold a numeric value or either a unit or per
      # unit attribute, <tt.self</tt> is returned.
      #
      def convert_unit(options={})
        return self unless has_numeric_value? and (unit or per_unit)
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
