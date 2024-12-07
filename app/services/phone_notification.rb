class PhoneNotification
  require 'twilio-ruby'

  def self.sms_message(recipient_number, message, sender_number = Settings.twilio.number)
    get_client.messages.create(
      to: recipient_number,
      from: sender_number,
      body: message
    )
  rescue Twilio::REST::RestError => e
    Rails.logger.error(e.message)
  end

  def self.voice_call(recipient_number, message)
    get_client.calls.create(
      to: recipient_number,
      from: Settings.twilio.number,
      url: "http://twimlets.com/message?Message%5B0%5D=#{URI.escape(message)}"
    )
  rescue Twilio::REST::RestError => e
    Rails.logger.error(e.message)
  end

  def self.get_client
    Twilio::REST::Client.new(Settings.twilio.account_sid, Settings.twilio.auth_token)
  end
end
