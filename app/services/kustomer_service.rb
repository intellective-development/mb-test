class KustomerError < StandardError; end

class KustomerService
  require 'faraday'

  def initialize(url, key)
    @key = key
    @conn = Faraday.new(url: url)
  end

  def update_user(user)
    # try to find user by email in Kustomer
    response = do_fetch_user(user.email)

    case response.status
    when 200
      # found the user, so we update
      body = JSON.parse(response.body)

      if !body['data'].nil? && !body['data']['id'].nil?
        kustomer_id = body['data']['id']
        do_update_user(user, kustomer_id)
      end
    else
      # user not found, so we create
      do_create_user(user)
    end
  end

  private

  def do_update_user(user, kustomer_id)
    url = "/customers/#{kustomer_id}"
    put(url, user.as_kustomer_user)
  end

  def do_create_user(user)
    url = '/customers'
    post(url, user.as_kustomer_user)
  end

  def do_fetch_user(email)
    url = "/customers/email=#{email}"
    get(url)
  end

  def post(url, body)
    @conn.post do |req|
      req.url("/v1#{url}")
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{@key}"
      req.body = body.to_json
    end
  end

  def put(url, body = nil)
    @conn.put do |req|
      req.url("/v1#{url}")
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{@key}"
      req.body = body.to_json unless body.nil?
    end
  end

  def get(url)
    @conn.get do |req|
      req.url("/v1#{url}")
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{@key}"
    end
  end
end
