
# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

require 'amee-data-abstraction'

::AMEE::DataAbstraction::CalculationCollection.class_eval { include AMEE::DataAbstraction::CalculationCollectionAnalyticsSupport }
::AMEE::DataAbstraction::TermsList.class_eval { include AMEE::DataAbstraction::TermsListAnalyticsSupport }
::AMEE::DataAbstraction::Term.class_eval { include AMEE::DataAbstraction::TermAnalyticsSupport }