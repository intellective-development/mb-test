class User
  class Lookup
    # This service is used by our FreshDesk integration to support
    # user lookups by email address and phone number.
    #
    # It is expecting either an :email or :phone parameter, and an
    # optional :ticket_id which references the FreshDesk ticket.
    def initialize(params, track: true)
      @params = params
      @track  = track
      @user   = find_user
    end

    def call
      track_support_interaction if @track
      @user
    end

    private

    def track_support_interaction
      return false unless @user

      SupportInteraction.find_or_create_by(support_interaction_params)
    end

    def support_interaction_params
      {
        user_id: @user.id,
        order_id: find_likely_order&.id,
        external_ticket_id: @params[:ticket_id],
        channel: SupportInteraction.channels[:freshdesk_ticket]
      }
    end

    # We don't know with certainty to which order a support interaction relates,
    # rather we approximate by taking the most recent order (if any) placed in
    # the past 14 days.
    def find_likely_order
      @user.orders.finished.where(completed_at: 2.weeks.ago..Time.current).last
    end

    def find_user
      user = RegisteredAccount.find_by(email: @params[:email])&.user                     if @params[:email]
      user ||= Address.shipping.find_by(normalized_phone: normalized_phone)&.addressable if @params[:phone]
      user
    end

    def normalized_phone
      PhonyRails.normalize_number(@params[:phone])
    end
  end
end
