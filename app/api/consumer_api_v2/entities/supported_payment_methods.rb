class ConsumerAPIV2::Entities::SupportedPaymentMethods < Grape::Entity
  expose :credit_card do |_supplier_profile|
    true
  end
  expose :apple_pay, &:apple_pay_supported?
  expose :android_pay do |_supplier_profile|
    false
  end
end
