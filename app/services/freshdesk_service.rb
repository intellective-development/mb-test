class FreshdeskService
  require 'faraday'

  DEFAULT_TICKET_PARAMS = {
    email: 'squirrel@minibardelivery.com',
    source: 2,
    priority: 2,
    status: 2
  }.freeze

  def create_ticket(params)
    client.post do |request|
      request.url 'api/v2/tickets'
      request.headers['Content-Type'] = 'application/json'
      request.body = DEFAULT_TICKET_PARAMS.merge(params).to_json
    end
  end

  private

  def client
    @client ||= Faraday.new(url: ENV['FRESHDESK_URL'])
    @client.basic_auth(ENV['FRESHDESK_USERNAME'], ENV['FRESHDESK_PASSWORD'])
    @client
  end
end
