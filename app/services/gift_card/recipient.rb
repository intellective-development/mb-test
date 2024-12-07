module GiftCard
  class Recipient
    attr_accessor :email

    # CR: Scoping out this logic because email might or might not be related to a real user.

    def initialize(email)
      @email = email
    end

    def gift_cards
      Coupon.active.at(Time.zone.now).sent(Time.zone.now).where(recipient_email: email)
    end

    def segment_id
      Digest::SHA256.hexdigest(String(email).downcase)
    end

    def exists_in_db?
      # sends a "signal" to Iterable to start a workflow to remove the user
      # only if user has no orders/accounts/coupons
      return true if Order.exists?(email: email)
      return true if RegisteredAccount.exists?(email: email)
      return true if RegisteredAccount.exists?(contact_email: email)
      return true if Coupon.exists?(recipient_email: email)
      return true if ZipcodeWaitlist.exists?(email: email)

      false
    end

    def as_segment_recipient
      {
        user_id: segment_id,
        traits: {
          email: email,
          gift_cards: active_gift_cards,
          gift_card_totals: gift_card_totals
        }
      }
    end

    private

    def gift_card_totals
      {
        count: active_gift_cards.count,
        available: active_gift_cards.sum { |gc| gc[:available] }
      }
    end

    def active_gift_cards
      @active_gift_cards ||= gift_cards.map do |gift_card|
        next unless (balance = gift_card.balance).positive?

        {
          id: gift_card.id,
          code: gift_card.code.upcase,
          amount: gift_card.amount.to_f,
          available: balance.to_f,
          createdAt: gift_card.created_at,
          lastTimeUsed: gift_card.orders.finished.completed_desc.last&.completed_at
        }
      end.compact
    end
  end
end
