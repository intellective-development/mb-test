require_relative '../../config/initializers/float_module'
class ValueSplitter
  attr_reader :limit, :value

  def initialize(value, limit: nil)
    @value = BigDecimal(value, 15)
    @limit = BigDecimal(limit, 15) unless limit.nil?
  end

  def split(total, size)
    # Ruby 2.4 changed the behavior here, so to avoid an error we
    # need to check the input is not a string.
    return BigDecimal(0) if total.is_a?(String) || size.is_a?(String)

    big_total = BigDecimal(total, 15)
    big_size = BigDecimal(size, 15)
    return BigDecimal('0') if @value.zero? || big_total.zero?

    within_limit round_split((big_size / big_total) * @value)
  end

  private

  def round_split(value)
    cents = (value * BigDecimal('100')).to_i
    remainder = cents % BigDecimal('1')

    if remainder == BigDecimal('0')
      value.round(2)
    elsif remainder < BigDecimal('0.5')
      value.round(2, BigDecimal::ROUND_DOWN)
    elsif remainder > BigDecimal('0.5')
      value.round(2, BigDecimal::ROUND_UP)
    elsif cents.even?
      value.round(2, BigDecimal::ROUND_DOWN)
    else
      value.round(2, BigDecimal::ROUND_UP)
    end
  end

  def within_limit(value)
    return value if limit.nil?

    value > limit ? limit : value
  end
end
