class BaseNotifier < ActionMailer::Base
  include MinibarMailer

  default from: "Minibar Delivery <#{Settings.admin_email}>"

  private

  def format_subject(subject)
    ENV['ENV_NAME'].present? && %w[production master].exclude?(ENV['ENV_NAME']) ? "[#{ENV['ENV_NAME']}] " + subject : subject
  end
end
