# frozen_string_literal: true

module Memberships
  class WebhookWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: false, queue: 'internal'

    def perform_with_error_handling(params, retry_job: true)
      membership = Membership.find_by(subscription_id: params[:subscription_id])

      return retry_later(params, retry_job) unless membership.present?

      subscription = subscription_api.find(params[:subscription_id])
      notification = build_notification(params[:kind], subscription)

      Memberships::Webhook.new(notification).call
    end

    private

    def retry_later(params, retry_job)
      return unless retry_job

      Memberships::WebhookWorker.perform_in(60.minutes, params, retry_job: false)
    end

    def subscription_api
      Braintree::Configuration.gateway.subscription
    end

    def build_notification(kind, subscription)
      OpenStruct.new(kind: kind, subscription: subscription)
    end
  end
end
