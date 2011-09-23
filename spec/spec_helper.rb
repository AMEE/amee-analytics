require 'rubygems'
require 'spec'

require 'amee-analytics'
require 'amee-data-persistence'
require 'amee/data_abstraction/persistence_support.rb'
require 'amee/data_abstraction/calculation_collection_analytics_support'
require 'amee/data_abstraction/terms_list_analytics_support'
require 'amee/data_abstraction/term_analytics_support'

AMEE::DataAbstraction::OngoingCalculation.class_eval {
  include AMEE::DataAbstraction::PersistenceSupport
}
AMEE::DataAbstraction::CalculationCollection.class_eval { include AMEE::DataAbstraction::CalculationCollectionAnalyticsSupport }
AMEE::DataAbstraction::TermsList.class_eval { include AMEE::DataAbstraction::TermsListAnalyticsSupport }
AMEE::DataAbstraction::Term.class_eval { include AMEE::DataAbstraction::TermAnalyticsSupport }

RAILS_ROOT = '.'

Spec::Runner.configure do |config|
  config.mock_with :flexmock
end

def initialize_calculation_set
  eval "Calculations = AMEE::DataAbstraction::CalculationSet.new {
      calculation{
        name 'Electricity'
        label :electricity
        path '/business/energy/electricity/grid'
        drill {
          label :country
          path 'country'
          fixed 'Argentina'
        }
        profile {
          label :usage
          name 'Electricity Used'
          path 'energyPerTime'
          default_unit :kWh
        }
        output {
          label :co2
          name 'Carbon Dioxide'
          path :default
          default_unit :t
        }
      }
      calculation{
        name 'Transport'
        label :transport
        path '/transport/defra/vehicle'
        drill {
          label :type
          path 'type'
          name 'Type'
        }
        drill {
          label :size
          path 'size'
          name 'Size'
        }
        drill {
          label :fuel
          path 'fuel'
          name 'Fuel'
        }
        profile {
          label :distance
          name 'distance'
          path 'distance'
          default_unit :km
        }
        output {
          label :co2
          name 'Carbon Dioxide'
          path :default
          default_unit :t
        }
      }
    }"
end

def add_elec_calc(act,res)
  calc = Calculations[:electricity].begin_calculation
  calc['usage'].value act
  calc['co2'].value res
  return calc
end

def add_transport_calc(act,res)
  calc = Calculations[:transport].begin_calculation
  calc['distance'].value act
  calc['co2'].value res
  return calc
end

VALID_ATTRIBUTES = [{ :profile_item_uid => "G8T8E8SHSH46",
                      :calculation_type => :electricity,
                      :country => {:value => 'Argentina'},
                      :usage => {:value => 500, :unit => Unit.kWh},
                      :co2 => {:value => 1234.5, :unit => Unit.kg} },
                    { :profile_item_uid => "RUEU38490R0R",
                      :calculation_type => :electricity,
                      :country => {:value => 'Argentina'},
                      :usage => {:value => 12, :unit => Unit.kWh},
                      :co2 => {:value => 6, :unit => Unit.kg} }]

def find_single_mock
  flexmock(AMEE::DataAbstraction::OngoingCalculation) do |mock|
    mock.should_receive(:find).and_return(single_db_calc(VALID_ATTRIBUTES.first))
  end
end

def find_many_mock
  flexmock(AMEE::DataAbstraction::OngoingCalculation) do |mock|
    mock.should_receive(:find).and_return(many_db_calc)
  end
end

def single_db_calc(data)
  calc = Calculations.calculations[:electricity].begin_calculation
  calc.db_calculation = data.delete(:calculation_type)
  calc.choose_without_validation!(data)
  return calc
end

def many_db_calc
  array = VALID_ATTRIBUTES.map do |data|
    single_db_calc(data)
  end
  return array
end