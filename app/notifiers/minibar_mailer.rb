module MinibarMailer
  extend ActiveSupport::Concern

  included do
    helper :application

    layout 'email_ink' unless Rails.env.test?

    default from: "Minibar Delivery <#{Settings.admin_email}>"
  end

  private

  def format_subject(subject)
    ENV['ENV_NAME'].present? && %w[production master].exclude?(ENV['ENV_NAME']) ? "[#{ENV['ENV_NAME']}] " + subject : subject
  end
end
