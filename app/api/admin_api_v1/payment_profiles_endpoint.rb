class AdminAPIV1::PaymentProfilesEndpoint < BaseAPIV1
  namespace :payment_profiles do
    desc 'Search payment_profiles'
    params do
      optional :user_id, type: Integer
    end
    get do
      payment_profiles = PaymentProfile.where(user_id: params[:user_id])

      present :payment_profiles, payment_profiles, with: AdminAPIV1::Entities::Query::PaymentProfileEntity
    end
  end
end
