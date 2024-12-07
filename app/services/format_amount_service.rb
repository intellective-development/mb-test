class FormatAmountService
  class << self
    def call(amount)
      return 0.0 if amount.nil?

      amount.to_f.round_at(2)
    end
  end
end
