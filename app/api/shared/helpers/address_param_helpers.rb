module Shared::Helpers::AddressParamHelpers
  extend Grape::API::Helpers

  params :location do
    optional :address_id, type: Integer, desc: 'Delivery address ID.'
    optional :aid,        type: Integer, desc: 'Delivery address ID.'
    optional :coords, type: Hash do
      optional :lng,       type: Float, desc: 'Longitude', allow_blank: false
      optional :lat,       type: Float, desc: 'Latitude',  allow_blank: false
      optional :longitude, type: Float, desc: 'Longitude', allow_blank: false
      optional :latitude,  type: Float, desc: 'Latitude',  allow_blank: false
      exactly_one_of :lng, :longitude
      exactly_one_of :lat, :latitude
    end
    optional :address, type: Hash do
      requires :address1, type: String, desc: 'Address 1', allow_blank: false
      optional :address2, type: String, desc: 'Address 2', default: ''
      optional :city,     type: String, desc: 'City'
      optional :state,    type: String, desc: 'State'
      requires :zip_code, type: String, desc: 'Zipcode', allow_blank: false
    end
  end

  params :create_address do
    requires :name,         type: String, allow_blank: false
    optional :company,      type: String, allow_blank: true
    requires :address1,     type: String, allow_blank: false
    optional :address2,     type: String, allow_blank: true, default: ''
    optional :city,         type: String, allow_blank: true
    optional :state,        type: String, allow_blank: true
    requires :zip_code,     type: String, regexp: /^(\d){5}/
    optional :phone,        type: String, allow_blank: true
    optional :latitude,     type: Float, allow_blank: true
    optional :longitude,    type: Float, allow_blank: true
    optional :default,      type: Boolean, allow_blank: true
    optional :sms_opt_in,   type: Boolean, default: false
    optional :email_opt_in, type: Boolean, default: false
  end
end
