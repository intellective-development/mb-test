require 'avatax'

module Avalara
  module Client
    def self.get_avalara_client
      AvaTax::Client.new(endpoint: ENV['AVALARA_ENDPOINT'], username: ENV['AVALARA_USERNAME'], password: ENV['AVALARA_PASSWORD'])
    end
  end
end
