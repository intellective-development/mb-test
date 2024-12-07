# frozen_string_literal: true

module Admin
  class RecaptchaDomainsController < BaseController
    before_action :load_domains, only: %i[index new]

    rescue_from ::Google::Cloud::Error do |e|
      flash[:error] = e.message
      redirect_back(fallback_location: root_path)
    end

    def index; end

    def new; end

    def update
      google_cloud_service.update_key_domains(domains_params) if Feature[:enable_gcp].enabled?

      redirect_to action: :index
    end

    private

    def load_domains
      @recaptcha_domains = Feature[:enable_gcp].enabled? ? google_cloud_service.allowed_domains : []
    end

    def google_cloud_service
      ::Google::CloudPlatform.new if Feature[:enable_gcp].enabled?
    end

    def domains_params
      params[:domains].reject(&:blank?)
    end
  end
end
