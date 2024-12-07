class ProductNameService
  attr_accessor :product_name, :brand_name, :normalized_product_name,
                :normalized_brand_name

  def initialize(product_grouping_name, brand_name)
    @product_name = String(product_grouping_name)
    @brand_name   = String(brand_name || 'Unknown Brand')

    @normalized_product_name = I18n.transliterate(@product_name.downcase)
    @normalized_brand_name   = I18n.transliterate(@brand_name.downcase)
  end

  def strip_brand
    if product_name_equals_brand_name?
      product_name
    elsif product_name_contains_full_brand_name?
      product_name[(brand_name.length + 1)..255].squish
    else
      product_name
    end
  end

  private

  def product_name_equals_brand_name?
    normalized_brand_name == normalized_product_name
  end

  def product_name_contains_full_brand_name?
    normalized_product_name.starts_with?(normalized_brand_name)
  end

  def product_name_contains_partial_brand_name?
    # TODO: Consider incorporating distance between brand name parts in the
    #       product name.
    overlapping_words = normalized_product_name_array & normalized_brand_name_array
    overlapping_words.any? && overlapping_words.include?(normalized_product_name_array[0])
  end

  def normalized_product_name_array
    @normalized_product_name_array ||= normalized_product_name.split(' ')
  end

  def normalized_brand_name_array
    @normalized_brand_name_array ||= normalized_brand_name.split(' ')
  end

  def product_name_array
    @product_name_array ||= product_name.split(' ')
  end

  def brand_name_array
    @brand_name_array ||= brand_name.split(' ')
  end
end
