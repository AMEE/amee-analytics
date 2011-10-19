calculation{

  name 'Electricity'
  label :electricity
  path '/business/energy/electricity/grid'
  drill {
    label :country
    path 'country'
    value 'Argentina'
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
    path 'default'
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
    path 'default'
    default_unit :t
  }
}