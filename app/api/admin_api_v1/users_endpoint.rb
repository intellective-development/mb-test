class AdminAPIV1::UsersEndpoint < BaseAPIV1
  namespace :users do
    desc 'Search users'
    params do
      optional :query, type: String
    end
    get do
      query = params[:query].presence || '*'

      users = User.search(
        query,
        fields: %i[id first_name last_name email],
        includes: [:account],
        where: { active: true },
        order: { first_name: :asc },
        per_page: 20,
        page: 1
      )

      present :users, users, with: AdminAPIV1::Entities::Query::UserEntity
    end
  end
end
