class ConsumerAPIV2::Entities::PaymentProfile < Grape::Entity
  expose :id
  expose :cc_type, as: :cc_card_type
  expose :last_digits, as: :cc_last_four
  expose :month, as: :cc_exp_month
  expose :year, as: :cc_exp_year
  expose :default
  expose :payment_type
  expose :address do
    expose :name do |payment_profile|
      payment_profile.address.name
    end
    expose :address1 do |payment_profile|
      payment_profile.address.address1
    end
    expose :address2 do |payment_profile|
      payment_profile.address.address2
    end
    expose :city do |payment_profile|
      payment_profile.address.city
    end
    expose :state do |payment_profile|
      payment_profile.address.state_name
    end
    expose :zip_code do |payment_profile|
      payment_profile.address.zip_code
    end
  end
end
