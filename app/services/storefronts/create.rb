# frozen_string_literal: true

module Storefronts
  # Service to create a storefront
  class Create
    attr_reader :params, :options

    def initialize(params, options = {})
      @params = params
      @options = options
    end

    def call
      @success = options[:with_client_id] ? generate_client_id : true
      @success = storefront.save if @success
      @success = create_membership_plan! if @success

      save_recaptcha_domains if @success

      self
    end

    def storefront
      @storefront ||= Storefront.new(params.except(:membership_plans, :recaptcha_domains))
    end

    def success?
      @success
    end

    protected

    def generate_client_id
      storefront.generate_client_id
      storefront.errors.empty?
    end

    def create_membership_plan!
      return true if !params[:membership_plans] || params[:membership_plans][:state] != 'active'

      MembershipPlans::Create.new(params[:membership_plans].to_h.merge(storefront_id: storefront.id)).call.success?
    end

    def save_recaptcha_domains
      return if recaptcha_domains.blank?

      ::Google::CloudPlatform.new.update_key_domains(recaptcha_domains) if Feature[:enable_gcp].enabled?
    end

    def recaptcha_domains
      params[:recaptcha_domains]&.[](:names)&.reject(&:blank?) || []
    end
  end
end
