class ConsumerAPIV2::Entities::PaymentProfileUpdateLink < Grape::Entity
  expose :id
  expose :expire_at
  expose :order_number do |payment_profile_update_link|
    payment_profile_update_link.order.number
  end
  expose :address do
    expose :name do |payment_profile_update_link|
      payment_profile_update_link.order.bill_address.name
    end
    expose :address1 do |payment_profile_update_link|
      payment_profile_update_link.order.bill_address.address1
    end
    expose :address2 do |payment_profile_update_link|
      payment_profile_update_link.order.bill_address.address2
    end
    expose :city do |payment_profile_update_link|
      payment_profile_update_link.order.bill_address.city
    end
    expose :state do |payment_profile_update_link|
      payment_profile_update_link.order.bill_address.state_name
    end
    expose :zip_code do |payment_profile_update_link|
      payment_profile_update_link.order.bill_address.zip_code
    end
  end
end
