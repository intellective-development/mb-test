class ConsumerAPIV2::AuthorizerEndpoint < Grape::API
  format :json

  resource :authorizer do
    get :anonymous do
      validate_device_udid!

      present :user, @user, with: ConsumerAPIV2::Entities::AuthorizerContextUser
      present :application, doorkeeper_application, with: ConsumerAPIV2::Entities::AuthorizerContextApplication
      present :storefront, storefront, with: ConsumerAPIV2::Entities::AuthorizerContextStorefront
    end

    get :authenticated do
      authenticate!
      validate_device_udid!

      present :user, @user, with: ConsumerAPIV2::Entities::AuthorizerContextUser
      present :application, doorkeeper_application, with: ConsumerAPIV2::Entities::AuthorizerContextApplication
      present :storefront, storefront, with: ConsumerAPIV2::Entities::AuthorizerContextStorefront
    end

    get :admin do
      authenticate!
      validate_device_udid!
      error!('Unauthorized', 403) unless @user.admin?

      present :user, @user, with: ConsumerAPIV2::Entities::AuthorizerContextUser
      present :application, doorkeeper_application, with: ConsumerAPIV2::Entities::AuthorizerContextApplication
      present :storefront, storefront, with: ConsumerAPIV2::Entities::AuthorizerContextStorefront
    end

    get :super_admin do
      authenticate!
      validate_device_udid!
      error!('Unauthorized', 403) unless @user.super_admin?

      present :user, @user, with: ConsumerAPIV2::Entities::AuthorizerContextUser
      present :application, doorkeeper_application, with: ConsumerAPIV2::Entities::AuthorizerContextApplication
      present :storefront, storefront, with: ConsumerAPIV2::Entities::AuthorizerContextStorefront
    end
  end
end
