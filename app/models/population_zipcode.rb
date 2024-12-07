# == Schema Information
#
# Table name: population_zipcodes
#
#  id         :integer          not null, primary key
#  zipcode    :string
#  population :integer
#
# Indexes
#
#  index_population_zipcodes_on_zipcode  (zipcode)
#

class PopulationZipcode < ActiveRecord::Base
end
