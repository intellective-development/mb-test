class SevenElevenAPI < BaseAPI
  format :json

  helpers do
    def authenticate!
      request_token = headers['X-Api-Token']
      valid_token = ENV['SEVEN_ELEVEN_NOW_WEBHOOK_TOKEN']

      error!('Missing or invalid API Token', 401) unless request_token == valid_token
    end
  end

  namespace :stores do
    desc 'Endpoint returning active 7-Eleven stores.'
    before do
      authenticate!
    end
    get do
      stores = Supplier
               .where(active: true, dashboard_type: Supplier::DashboardType::SEVEN_ELEVEN)
               .where.not(external_supplier_id: nil)
               .order(display_name: :ASC)
               .pluck(:id, :display_name, :external_supplier_id)

      stores_payload = stores.map { |s| { id: s[0], name: s[1], external_store_id: s[2] } }

      status 200
      { count: stores_payload.count, data: stores_payload }
    end
  end
end
