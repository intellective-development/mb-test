class GiftCardException < StandardError
  class AlreadyCoveredError < GiftCardException; end
  class DigitalOrderError < GiftCardException; end
  class InvalidCodeError < GiftCardException; end
  class ZeroBalanceError < GiftCardException; end
  class OrderAdjustmentError < GiftCardException; end
end
