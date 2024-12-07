class CouponTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if valid_coupon_type?(value)

    record.errors.add(attribute, "type must be #{valid_types_as_sentence}.")
  end

  def valid_coupon_type?(coupon_id)
    coupon = Coupon.find_by(id: coupon_id)
    coupon && valid_types.include?(coupon.type)
  end

  def valid_types
    @valid_types ||= Array(options[:in])
  end

  def valid_types_as_sentence
    valid_types.to_sentence(last_word_connector: ' or ')
  end
end
