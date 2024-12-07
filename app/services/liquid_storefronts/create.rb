# frozen_string_literal: true

module LiquidStorefronts
  # LiquidStorefronts::Create
  class Create
    attr_reader :storefront, :error

    DEFAULT_OAUTH_APP_REDIRECT_URI = 'urn:ietf:wg:oauth:2.0:oob'

    def initialize(params:)
      @params = params.dup
    end

    def call
      ActiveRecord::Base.transaction do
        create_oauth_app
        create_storefront
      rescue StandardError => e
        @error = e.message

        raise ActiveRecord::Rollback
      end

      self
    end

    def success?
      @error.nil?
    end

    private

    attr_accessor :oauth_app

    def create_oauth_app
      @oauth_app = Doorkeeper.config.application_model.create!(
        name: @params[:name],
        redirect_uri: DEFAULT_OAUTH_APP_REDIRECT_URI
      )
    end

    def create_storefront
      attrs = @params.merge(oauth_application_id: @oauth_app.id)
      @storefront = Storefront.create!(attrs)
    end
  end
end
