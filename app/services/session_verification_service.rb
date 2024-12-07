class SessionVerificationService
  REDIS_PREFIX = 'SessionVerificationService'.freeze

  class << self
    def account_take_over?(user, session, request)
      return false unless user&.persisted?
      return false if skip_account_take_over_check?(user)

      sift_score, decision = get_sift_decision(user, session, request)

      authenticated_session = insert_authenticated_session(user, session, request, sift_score)

      # Re-apply user decision (if any)
      case authenticated_session.reapply_user_last_decision
      when '$safe'
        return false
      when '$compromised'
        return true
      end

      # Apply Sift's decision
      case decision
      when 'session_looks_bad_account_takeover'
        if user_already_emailed?(user)
          authenticated_session.do_not_notify_by_email(user.email)
        else
          email_access_alert(user, session, request, authenticated_session)
        end
        true
      when 'watch_session_account_takeover'
        # email_access_warning(user, session, request, authenticated_session)
        false
      else
        # "session_looks_ok_account_takeover" or no decision (pushed to Sift queue)
        false
      end
    end

    def confirm_by_token(token, request)
      apply_user_decision(token, request, confirm: true)
    end

    def deny_by_token(token, request)
      apply_user_decision(token, request, confirm: false)
    end

    def delay_to_secure_account_overdue?(user)
      user&.account&.ato_email_sent_at && Time.zone.now > user.account.ato_email_sent_at + ato_hours_to_secure_account.hours
    end

    def ato_emails_count(user)
      ato_emails_count_from = ato_emails_counter_reset_at(user) || 1.day.ago
      user
        .authenticated_sessions
        .email_sent
        .where('authenticated_sessions.created_at > ?', ato_emails_count_from).limit(ato_emails_per_day_cap).size
    end

    def reset_ato_email_count(user)
      authenticated_session = user.authenticated_sessions.create(
        notification_type: '$email',
        notification_status: '$manual_reset'
      )
      user.account&.ato_email_cleared
    end

    private

    def insert_authenticated_session(user, session, request, sift_score)
      user.authenticated_sessions.create(
        session_id: session.id,
        ip: request.remote_ip,
        user_agent: request.user_agent,
        sift_score: sift_score,
        recaptcha_v3_score: request.params ? request.params&.dig(:recaptcha_v3_result, :score) : 1
      )
    end

    def get_sift_decision(user, session, request)
      workflow_result = Fraud::LoginEvent.new(user, session, request, success: true).call_and_run_workflow
      workflow_result.values_at(:score, :decision)
    end

    def user_already_emailed?(user)
      ato_emails_count(user) >= ato_emails_per_day_cap
    end

    def ato_emails_counter_reset_at(user)
      user.authenticated_sessions.where(
        notification_type: '$email',
        notification_status: '$manual_reset'
      ).where('created_at > ?', 1.day.ago).last&.created_at
    end

    # def secure_account_on_behalf_of_user(user)
    #   tmp_password = SecureRandom.urlsafe_base64 + SecureRandom.urlsafe_base64
    #   user.account.reset_password(tmp_password, tmp_password)
    # end

    def email_access_alert(user, session, request, authenticated_session)
      authenticated_session.notify_by_email(user.email)
      notify_sift_of_email(user, session, request)
      DeviseNotifier.account_takeover_alert_instructions(
        user.account,
        authenticated_session
      ).deliver_later
      user.account.ato_email_sent
    end

    def email_access_warning(user, session, request, authenticated_session)
      authenticated_session.notify_by_email(user.email)
      notify_sift_of_email(user, session, request)
      DeviseNotifier.account_takeover_warning_instructions(
        user.account,
        authenticated_session
      ).deliver_later
    end

    def notify_sift_of_email(user, session, request)
      Fraud::SecurityNotificationEvent.new(
        user,
        session,
        request,
        type: '$email',
        status: '$sent'
      ).call_async
      Fraud::VerificationEvent.new(
        user,
        session,
        request,
        type: '$email',
        status: '$pending'
      ).call_async
    end

    def apply_user_decision(token, request, confirm:)
      authenticated_session = AuthenticatedSession.find_by(notification_token: token)
      return nil unless authenticated_session
      return nil if secure_token_expired?(authenticated_session)

      if confirm
        authenticated_session.confirm
      else
        authenticated_session.deny
      end

      authenticated_session.auto_confirm(
        remote_ip: request.remote_ip,
        user_agent: request.user_agent
      )

      authenticated_session.user&.account&.ato_email_cleared # Active user
      Fraud::SecurityNotificationEvent.from_authenticated_session(authenticated_session).call_async
      Fraud::VerificationEvent.from_authenticated_session(authenticated_session).call_async

      authenticated_session
    end

    def secure_token_expired?(session)
      Time.zone.now > session.created_at + ato_minutes_of_token_validity.minutes
    end

    def ato_emails_per_day_cap
      Redis.current&.get("#{REDIS_PREFIX}:ato_emails_per_day_cap")&.to_i || 3
    end

    def ato_hours_to_secure_account
      Redis.current&.get("#{REDIS_PREFIX}:ato_hours_to_secure_account")&.to_i || 72
    end

    def ato_minutes_of_token_validity
      Redis.current&.get("#{REDIS_PREFIX}:ato_minutes_of_token_validity")&.to_i || 72 * 60
    end

    # TODO: Move that logic to Sift once they implement custom fields in ATO workflow automations
    def skip_account_take_over_check?(user)
      user.doorkeeper_application&.skip_account_take_over_check || user.has_any_role?(:supplier)
    end
  end
end
