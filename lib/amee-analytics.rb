# Copyright (C) 2011 AMEE UK Ltd. - http://www.amee.com
# Released as Open Source Software under the BSD 3-Clause license. See LICENSE.txt for details.

require 'rubygems'
require 'amee-data-abstraction'
require 'amee-data-persistence'
require 'amee/analytics/result'
require 'amee/analytics/calculation_collection_analytics_support'
require 'amee/analytics/terms_list_analytics_support'
require 'amee/analytics/term_analytics_support'

::AMEE::DataAbstraction::CalculationCollection.send :include, AMEE::Analytics::CalculationCollectionAnalyticsSupport
::AMEE::DataAbstraction::TermsList.send :include, AMEE::Analytics::TermsListAnalyticsSupport
::AMEE::DataAbstraction::Term.send :include, AMEE::Analytics::TermAnalyticsSupport