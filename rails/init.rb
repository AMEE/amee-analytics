require 'amee-data-abstraction'

::AMEE::DataAbstraction::CalculationCollection.class_eval { include AMEE::DataAbstraction::CalculationCollectionReportingSupport }
::AMEE::DataAbstraction::TermsList.class_eval { include AMEE::DataAbstraction::TermsListReportingSupport }
::AMEE::DataAbstraction::Term.class_eval { include AMEE::DataAbstraction::TermReportingSupport }