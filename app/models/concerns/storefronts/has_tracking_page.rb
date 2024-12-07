# frozen_string_literal: true

module Storefronts
  # Storefronts::HasTrackingPage
  module HasTrackingPage
    extend ActiveSupport::Concern

    def tracking_page_url
      URI::HTTPS.build(host: tracking_page_hostname, path: "/#{permalink}").to_s
    end

    def tracking_page_order_preview_url
      "#{tracking_page_url}/order/preview?secret=#{tracking_page_order_preview_secret}"
    end

    def tracking_page_order_preview_secret
      Digest::SHA256.hexdigest(created_at.to_i.to_s)
    end
  end
end
