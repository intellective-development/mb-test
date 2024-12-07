# This concern implements helper-method to report message to sentry with special tag, indicating, this is a
# critical warning. Sentry should be configured to report all such messages to Slack channel
module CriticalWarning
  extend ActiveSupport::Concern

  def critical_warning(message)
    Sentry.with_scope do |scope|
      scope.set_tags('report_to_slack': 'true')
      Sentry.capture_message(message)
    end
  end
end
