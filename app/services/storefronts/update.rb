module Storefronts
  class Update
    attr_reader :params, :storefront

    def initialize(storefront, params)
      @storefront = storefront
      @params     = params
    end

    def call
      @success = storefront.update(params.except(:membership_plans, :recaptcha_domains))
      @success = update_membership_plan! if @success
      save_recaptcha_domains if @success

      self
    end

    def success?
      @success
    end

    protected

    def update_membership_plan!
      return true unless params[:membership_plans]

      membership_plan = storefront.membership_plan
      result =
        if membership_plan
          MembershipPlans::Update.new(membership_plan, params[:membership_plans]).call
        elsif params[:membership_plans][:state] == 'active'
          MembershipPlans::Create.new(params[:membership_plans].to_h.merge(storefront_id: storefront.id)).call
        end
      result.nil? || result.success?
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
