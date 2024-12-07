# == Schema Information
#
# Table name: authenticated_sessions
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  session_id          :string
#  ip                  :string
#  user_agent          :text
#  created_at          :datetime
#  updated_at          :datetime
#  sift_score          :float
#  notified_value      :string
#  notification_type   :string
#  notification_token  :string
#  notification_status :string
#  verification_status :string
#  recaptcha_v3_score  :decimal(8, 2)
#
# Indexes
#
#  index_authenticated_sessions_on_created_at          (created_at)
#  index_authenticated_sessions_on_last_session        (ip,user_id,user_agent,notification_status)
#  index_authenticated_sessions_on_notification_token  (notification_token)
#  index_authenticated_sessions_on_user_id             (user_id)
#

class AuthenticatedSession < ActiveRecord::Base
  belongs_to :user

  SAFE_STATES = [
    '$safe',
    '$auto_safe',
    '$sticky_safe'
  ].freeze

  COMPROMISED_STATES = [
    '$compromised',
    '$sticky_compromised'
  ].freeze

  EMAILED_STATES = [
    '$sent', '$safe', '$compromised'
  ].freeze

  scope :email_sent, -> { where(notification_type: '$email', notification_status: EMAILED_STATES) }

  def notify_by_email(email)
    update(
      notified_value: email,
      notification_type: '$email',
      notification_token: generate_token,
      notification_status: '$sent',
      verification_status: '$pending'
    )
  end

  def do_not_notify_by_email(email)
    update(
      notified_value: email,
      notification_type: '$email',
      notification_status: '$not_sent'
    )
  end

  def confirm
    update(
      notification_token: nil,
      notification_status: '$safe',
      verification_status: '$success'
    )
  end

  def deny
    update(
      notification_token: nil,
      notification_status: '$compromised',
      verification_status: '$failure'
    )
  end

  def reapply_user_last_decision
    last_decision = AuthenticatedSession.where(
      user_id: user_id,
      ip: ip,
      notification_status: SAFE_STATES + COMPROMISED_STATES
    ).last&.notification_status
    case last_decision
    when *SAFE_STATES
      update(notification_status: '$sticky_safe')
      '$safe'
    when *COMPROMISED_STATES
      update(notification_status: '$sticky_compromised')
      '$compromised'
    end
  end

  def auto_confirm(remote_ip:, user_agent:)
    # User's confirming/denying access can occur on another device
    # mark that other device as safe
    dup.update(
      ip: remote_ip,
      user_agent: user_agent,
      notification_status: '$auto_safe',
      verification_status: '$success'
    )
  end

  private

  def generate_token
    loop do
      token = Devise.friendly_token
      break token unless AuthenticatedSession.exists?(notification_token: token)
    end
  end
end
