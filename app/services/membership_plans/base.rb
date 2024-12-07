module MembershipPlans
  class Base
    attr_reader :params

    delegate :storefront, to: :membership_plan, allow_nil: true

    NAME = 'Topflight Society'.freeze

    def membership_plan
      @membership_plan ||= MembershipPlan.new(default_params.merge(params))
    end

    def success?
      @success
    end

    protected

    def default_params
      { state: :active, billing_day_of_month: nil, billing_frequency: 12, name: NAME }
    end

    def plan_api
      Braintree::Configuration.gateway.plan
    end

    def env
      return 'dev' if Rails.env.development?
      return nil if ENV['APP_NAME'] == 'production'

      ENV['APP_NAME']
    end

    def name
      [("[#{env}]" if env), storefront&.name, membership_plan.name].compact.join(' ')
    end

    def plan_id
      [env, membership_plan.id].compact.join('_')
    end
  end
end
