class LookupAPIV1 < BaseAPIV1
  format :json
  prefix 'api/lookup'
  version 'v1', using: :path

  helpers do
    def authenticate!
      return false if headers['Authorization'].nil?

      headers['Authorization'] == "Token #{ENV['LOOKUP_AUTH_TOKEN']}"
    end
  end

  desc 'Looks up customer details with either an email address or phone number'
  params do
    optional :email, type: String, desc: 'Email Address'
    optional :phone, type: String, desc: 'Phone Number'
    optional :ticket_id, type: String, desc: 'ID of FreshDesk ticket'
    at_least_one_of :email, :phone
  end
  before do
    error!('Unauthorized', 401) unless authenticate!
  end
  get do
    user = User::Lookup.new(params).call

    present :user, user, with: LookupAPIV1::Entities::User
  end
end
