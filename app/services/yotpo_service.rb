class YotpoService
  include SentryNotifiable

  BATCH_SIZE = 50

  def initialize
    @utoken = utoken
    @base_url = "/apps/#{ENV['YOTPO_APP_KEY']}"
  end

  def create_order(order)
    return true if order.canceled?
    return true unless order.minibar?

    @params = order_info(order).merge(auth_params)

    @response = Yotpo.create_new_purchase @params
    return true if response_successful?

    log_error
    false
  end

  def create_mass_products(variant_ids)
    url = "#{@base_url}/products/mass_create"
    variants = Variant.active.available.where(id: variant_ids).includes(:product)
    @params = {
      utoken: utoken,
      result_callback_url: result_callback_url,
      products: feed_products_info(variants)
    }

    @response = Yotpo.post(url, @params)
    return true if response_successful?

    log_error
    false
  end

  def cancel_order(order_id)
    @params = {
      utoken: utoken,
      orders: [{
        "order_id": order_id
      }]
    }

    url = "#{@base_url}/purchases?#{@params.to_query}"

    @response = Yotpo.delete(url)

    log_error unless response_successful?
    response_successful?
  end

  def update_mass_products(batch_id, current_page)
    yotpo_webhook_log = YotpoWebhookLog.find_or_create_by(batch_id: batch_id, page: current_page, success: false)

    url = "#{@base_url}/products/mass_update"

    variants = Variant.active.available.page(current_page).per(BATCH_SIZE).includes(:product)
    return unless variants.any?

    next_page = current_page + 1

    @params = {
      utoken: utoken,
      products: feed_products_info(variants),
      result_callback_url: "#{ENV['API_URL']}/webhooks/yotpo/update_mass_products?page=#{next_page}&batch_id=#{batch_id}"
    }

    @response = Yotpo.put(url, @params)

    yotpo_webhook_log.update(success: response_successful?)

    log_error unless response_successful?
    response_successful?
  end

  def create_product_grouping(product_grouping)
    url = "#{@base_url}/products_groups"
    @params = {
      name: product_grouping.name,
      utoken: utoken
    }

    @response = Yotpo.post(url, @params)
    return true if response_successful?

    log_error
    false
  end

  def add_products_to_product_grouping(product_grouping, product_skus)
    product_grouping_name = product_grouping.name
    url = "#{@base_url}/products_groups/#{product_grouping_name}"

    @params = {
      product_ids_to_add: product_skus,
      utoken: utoken
    }

    @response = Yotpo.put(url, @params)
    return true if response_successful?

    log_error
    false
  end

  private

  def response_successful?
    @response.body.code == 200
  end

  def log_error
    message_sentry_and_log(@response.body.message,
                           { backtrace: caller,
                             response: @response.body,
                             errors: @response.body.errors,
                             params: @params })
  end

  def auth_params
    {
      utoken: utoken,
      app_key: ENV['YOTPO_APP_KEY']
    }
  end

  def order_info(order)
    {
      email: order.email,
      customer_name: order.user_name,
      order_id: order.number,
      platform: 'general' || order.client,
      products: order_products_info(order),
      order_date: Time.zone.today.strftime('%Y-%m-%d'),
      customer: customer_info(order),
      custom_properties: custom_properties(order)
    }
  end

  def variant_url(variant)
    "https://#{ENV['WEB_STORE_URL'] && URI(ENV['WEB_STORE_URL']).host}/store/product/#{variant.product.product_size_grouping_permalink}"
  end

  def order_products_info(order)
    variants = order.order_items.map(&:variant)
    products = {}

    variants.each do |variant|
      permalink = variant.product.permalink

      products[permalink] = {
        name: variant.pretty_name,
        url: variant_url(variant),
        image: variant.featured_image,
        price: variant.price.to_s
      }
      brand = variant.brand_name&.tr(',', '') # Comply with Yotpo guidelines
      products[permalink][:product_tags] = brand if brand && brand != 'Unknown Brand'
    end

    products
  end

  def customer_info(order)
    address = order.ship_address
    return {} if address.nil? # TECH-2881 related PR #2389

    {
      state: address.state_name,
      country: address.country&.abbreviation || 'US',
      address: address.address1,
      phone_number: address.phone
    }
  end

  def custom_properties(order)
    [{
      name: 'suppliers',
      value: order.suppliers.map(&:name).join(', ')
    }]
  end

  def feed_product_info(variant)
    {
      name: variant.pretty_name,
      url: variant_url(variant),
      image: variant.featured_image,
      description: variant.original_name,
      group_name: variant.product.product_size_grouping.permalink.truncate(100, omission: ''),
      currency: 'USD',
      price: variant.price.to_s
    }
  end

  def feed_products_info(variants)
    products = {}
    variants.each { |variant| products[variant.product.permalink] = feed_product_info(variant) }

    products
  end

  def result_callback_url
    "#{ENV['API_URL']}/webhooks/yotpo/mass_products"
  end

  def utoken
    return @utoken if @utoken

    response = Yotpo.get_oauth_token app_key: ENV['YOTPO_APP_KEY'], secret: ENV['YOTPO_SECRET_KEY']
    response.body.access_token
  end
end
