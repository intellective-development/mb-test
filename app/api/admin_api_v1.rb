class AdminAPIV1 < BaseAPIV1
  format :json
  prefix 'api/admin'
  version 'v1', using: :path

  TRIAGE_POINT_AWARD = 4

  helpers AuthenticateWithToken

  helpers do
    def authenticate!(user_id = nil)
      error!('Missing or invalid user', 403) if current_user.nil? || (user_id && current_user.id != user_id.to_i)
    end

    def current_user
      @current_user ||= begin
        error!('No User', 400) if resource_owner.blank?
        error!('Unauthorized', 401) unless resource_owner.admin? # don't allow unless user has admin role

        resource_owner
      end
    end

    def award_points(point_award = TRIAGE_POINT_AWARD)
      Count.increment("hunger_games##{current_user.id}", point_award)
    end
  end

  # NOTE: doorkeeper is running oauth authentication for some of these endpoints and not for others
  # Endpoints that whose class definition start with `doorkeeper_for :all` are subject to oauth authentication
  mount AdminAPIV1::ActivationEndpoint
  mount AdminAPIV1::InventoryEndpoint
  mount AdminAPIV1::ProductsEndpoint
  mount AdminAPIV1::QueryEndpoint
  mount AdminAPIV1::SessionEndpoint
  mount AdminAPIV1::TriageEndpoint
  mount AdminAPIV1::CocktailsEndpoint
  mount AdminAPIV1::DealsEndpoint
  mount AdminAPIV1::BrandsEndpoint
  mount AdminAPIV1::ProductSizeGroupingsEndpoint
  mount AdminAPIV1::UsersEndpoint
  mount AdminAPIV1::PaymentProfilesEndpoint
  mount AdminAPIV1::CnameRecordsEndpoint
  mount AdminAPIV1::RegisteredAccountsEndpoint
end
