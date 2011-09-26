
# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.
# 
# :title: Module: AMEE::DataAbstraction::TermAnalyticsSupport

module AMEE
  module Analytics
    
    # Mixin module for the <i>AMEE::DataAbstraction::Term</i> class, providing
    # methods for handling collections of calculations.
    #
    module TermAnalyticsSupport

      # Returns an instance of <i>Result</i> based upon the attributes of
      # <tt>self</tt>.
      #
      def to_result
        result_term = Result.new
        AMEE::DataAbstraction::TermsList::TermProperties.each do |attr|
          result_term.send(attr, self.send(attr))
        end
        return result_term
      end
     
    end
  end
end
