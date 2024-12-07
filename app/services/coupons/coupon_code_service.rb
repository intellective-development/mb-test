# frozen_string_literal: true

class Coupons::CouponCodeService
  # We want to restrict possible codes to easily readable characters
  CHARSET = %w[2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z].freeze
  CODE_LENGTH = 10
  MAX_PREFIX = 5

  def generate_code(prefix = nil)
    code = new_code(prefix) while code.nil? || Coupon.exists?(code: code.downcase)
    code
  end

  private

  def new_code(prefix)
    prefix = sanitize(prefix)
    "#{prefix}#{CHARSET.sample(CODE_LENGTH - prefix.size).join}"
  end

  def sanitize(prefix)
    return '' if prefix.nil?

    raise StandardError, "The max size of prefix is #{MAX_PREFIX} characters" if prefix.to_s.length > MAX_PREFIX

    prefix.to_s
  end
end
