class ConsumerAPIV2::Entities::ShippingAddress < Grape::Entity
  expose :id, unless: ->(address, _options) { address.cart_share? }
  expose :name, unless: ->(address, _options) { address.cart_share? }
  expose :company
  expose :address1
  expose :address2
  expose :city
  expose :state_name, as: :state
  expose :zip_code
  expose :phone
  expose :latitude  if { type: :has_coordinates }
  expose :longitude if { type: :has_coordinates }
end
