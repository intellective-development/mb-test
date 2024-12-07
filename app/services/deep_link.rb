class DeepLink
  module Web
    # eventually, we would like our web and mobile permalinks to match, but at the moment they do not
    def self.product_type(product_type, ancestors = nil)
      # we take an optional ancestors param, to avoid redundant db queries where possible
      self_and_ancestors = ancestors ? [*ancestors, product_type] : product_type.sorted_self_and_ancestors
      permalink_path = self_and_ancestors.map(&:permalink).join('/')
      "/store/category/#{permalink_path}"
    end

    def self.tag(tag_name)
      "/store/promos/#{tag_name.parameterize}"
    end
  end

  def self.add_url_base(path)
    return path if String(path).starts_with?(DeepLink.url_base)

    "#{DeepLink.url_base}#{path}"
  end

  def self.product_type(product_type)
    if product_type.root?
      "#{DeepLink.url_base}/store/products/#{product_type.permalink}"
    else
      param_name = case product_type.depth
                   when 0 then 'hierarchy_category'
                   when 1 then 'hierarchy_type'
                   when 2 then 'hierarchy_subtype'
                   end

      "#{DeepLink.url_base}/store/products/#{product_type.root.permalink}?#{param_name}[]=#{product_type.permalink}"
    end
  end

  def self.product_grouping(product_grouping)
    "#{DeepLink.url_base}/store/product/#{product_grouping.permalink}"
  end

  def self.api_product_groupings_uri(query_string, suppliers, shipping_state = '')
    "/api/v2/supplier/#{suppliers.map(&:id).join(',')}/product_groupings?#{query_string}&shipping_state=#{shipping_state}"
  end

  def self.api_product_groupings(query_string, suppliers, shipping_state = '')
    "#{DeepLink.api_base}/api/v2/supplier/#{suppliers.map(&:id).join(',')}/product_groupings?#{query_string}&shipping_state=#{shipping_state}"
  end

  def self.api_related_products_uri(query_string, suppliers, shipping_state = '')
    "/api/v2/supplier/#{suppliers.map(&:id).join(',')}/related?#{query_string}&shipping_state=#{shipping_state}"
  end

  def self.api_related_products(query_string, suppliers, shipping_state = '')
    "#{DeepLink.api_base}/api/v2/supplier/#{suppliers.map(&:id).join(',')}/related?#{query_string}&shipping_state=#{shipping_state}"
  end

  def self.api_cocktails(query_string)
    query_string.to_s
  end

  def self.api_base
    ENV['API_URL'] || 'https://api.minibardelivery.com'
  end

  def self.url_base
    ENV['ASSET_HOST'] || 'https://minibardelivery.com'
  end
end
