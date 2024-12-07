class ExternalAPIV1::Entities::User < Grape::Entity
  expose :email
  expose :first_name
  expose :last_name
  expose :phone_numbers do |user|
    user.shipping_addresses.pluck(:phone).uniq.reject(&:blank?).map { |p| p.gsub(/\D/, '') }
  end
end
