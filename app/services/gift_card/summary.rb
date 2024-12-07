module GiftCard
  class Summary
    attr_accessor :email, :gift_cards

    def initialize(email, gift_cards, summary_file_url)
      @email = email
      @gift_cards = gift_cards
      @summary_file_url = summary_file_url
    end

    def segment_id
      Digest::SHA256.hexdigest(String(email).downcase)
    end

    def as_segment_event
      {
        summary: summary,
        summary_file_url: @summary_file_url
      }
    end

    def summary
      gift_cards.map do |coupon|
        {
          code: coupon.code.upcase,
          email: coupon.recipient_email,
          value: coupon.amount.to_f
        }
      end
    end
  end
end
