if defined?(AMEE::DataAbstraction::CalculationCollection)
  AMEE::DataAbstraction::CalculationCollection.class_eval { include AMEE::DataAbstraction::CalculationCollectionReportingSupport }
end

if defined?(AMEE::DataAbstraction::TermsList)
  AMEE::DataAbstraction::TermsList.class_eval { include AMEE::DataAbstraction::TermsListReportingSupport }
end

if defined?(AMEE::DataAbstraction::Term)
  AMEE::DataAbstraction::Term.class_eval { include AMEE::DataAbstraction::TermReportingSupport }
end