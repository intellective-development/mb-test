module StringHashable
  module_function

  def string_hash_code(value)
    hash = 0
    return hash unless value.is_a?(String)
    return hash if value.strip.empty?

    value.each_char do |char|
      hash = (((hash << 5) - hash) + char.ord + 2_147_483_648) % 4_294_967_296 - 2_147_483_648
      hash &= hash
    end
    hash
  end
end
