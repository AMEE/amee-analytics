
# Authors::   James Smith, Andrew Berkeley
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
# :title: Module: AMEE::DataAbstraction::TermAnalyticsSupport

module AMEE
  module DataAbstraction
    
    # Mixin module for the <i>AMEE::DataAbstraction::Term</i> class, providing
    # methods for handling collections of calculations.
    #
    module TermAnalyticsSupport

      # Returns an instance of <i>Result</i> based upon the attributes of
      # <tt>self</tt>.
      #
      def to_result
        result_term = Result.new
        TermsList::TermProperties.each do |attr|
          result_term.send(attr, self.send(attr))
        end
        return result_term
      end
     
    end
  end
end
