# == Schema Information
#
# Table name: covered_zipcodes_shipped
#
#  zipcode       :string
#  cities        :string           is an Array
#  states        :text             is an Array
#  shipping_type :text
#  contained     :integer          is an Array
#
# Indexes
#
#  index_covered_zipcodes_shipped_on_cities     (cities) USING gin
#  index_covered_zipcodes_shipped_on_contained  (contained) USING gin
#  index_covered_zipcodes_shipped_on_states     (states) USING gin
#  index_covered_zipcodes_shipped_on_zipcode    (zipcode)
#
class CoveredZipcodesShipped < ActiveRecord::Base
  self.table_name = 'covered_zipcodes_shipped'

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def self.zipcodes(params = {})
    scope = CoveredZipcodesShipped
    # Filter by search options
    scope = scope.where("#{params[:supplier_id]} = ANY(contained)")                                          if params[:supplier_id]
    scope = scope.where('zipcode = ?', params[:zipcode])                                                     if params[:zipcode]
    scope = scope.where('? = ANY(states)', params[:state])                                                   if params[:state]
    scope = scope.where("EXISTS (SELECT FROM unnest(cities) elem WHERE  elem ILIKE '%#{params[:city]}%')")   if params[:city]
    scope.joins('left join suppliers cont on cont.id = ANY(contained)')
         .select('zipcode, cities, states, shipping_type::text, ARRAY_REMOVE(ARRAY_AGG(cont.name), NULL) as contained_names')
         .group(1, 2, 3, 4)
  end
end
