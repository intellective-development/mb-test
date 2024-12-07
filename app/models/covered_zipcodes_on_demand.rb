# == Schema Information
#
# Table name: covered_zipcodes_on_demand
#
#  zipcode       :string
#  cities        :string           is an Array
#  states        :text             is an Array
#  shipping_type :text
#  contained     :integer          is an Array
#  overlapped    :integer          is an Array
#
# Indexes
#
#  index_covered_zipcodes_on_demand_on_cities      (cities) USING gin
#  index_covered_zipcodes_on_demand_on_contained   (contained) USING gin
#  index_covered_zipcodes_on_demand_on_overlapped  (overlapped) USING gin
#  index_covered_zipcodes_on_demand_on_states      (states) USING gin
#  index_covered_zipcodes_on_demand_on_zipcode     (zipcode)
#
class CoveredZipcodesOnDemand < ActiveRecord::Base
  self.table_name = 'covered_zipcodes_on_demand'

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end

  def self.zipcodes(params = {})
    scope = CoveredZipcodesOnDemand
    # Filter by search options
    scope = scope.where("#{params[:supplier_id]} = ANY(contained) or #{params[:supplier_id]} = ANY(overlapped)") if params[:supplier_id]
    scope = scope.where('zipcode = ?', params[:zipcode])                                                         if params[:zipcode]
    scope = scope.where('? = ANY(states)', params[:state])                                                       if params[:state]
    scope = scope.where("EXISTS (SELECT FROM unnest(cities) elem WHERE  elem ILIKE '%#{params[:city]}%')")       if params[:city]
    scope.joins('left join suppliers ov on ov.id = ANY(overlapped) left join suppliers cont on cont.id = ANY(contained)')
         .select('zipcode, cities, states, shipping_type::text, ARRAY_REMOVE(ARRAY_AGG(cont.name), NULL) as contained_names, ARRAY_REMOVE(ARRAY_AGG(ov.name), NULL) as overlapped_names')
         .group(1, 2, 3, 4)
  end
end
