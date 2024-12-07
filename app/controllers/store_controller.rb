class StoreController < ApplicationController
  layout 'minibar'

  # before_action :check_for_lockup, :check_load_font

  def render(options = nil, extra_options = {}, &block)
    @top_banner_message = TopBannerMessage.find_or_initialize_by(id: 1)
    @popup_banner_message = TopBannerMessage.find_or_initialize_by(id: 2)
    super(options, extra_options, &block)
  end

  def index
    if params[:is_test]
      setup_test_store
    elsif session_supplier.nil? || session_address.nil?
      # Address pop up when users (with no address) claim a cart
      if cookies[:cart_id] && cookies[:cart_claim]
        cookies.delete :cart_claim
        bootstrap_store_data
      else
        flash[:store_redirect_destination] = request.original_fullpath
        redirect_to root_path, error: 'Please enter an address'
      end
    else
      bootstrap_store_data
    end
    set_page_metadata
  end

  def show_product_grouping
    grouping_identifier = params[:product_grouping]

    @product_grouping = begin
      ProductSizeGrouping.includes(:view).active.find(grouping_identifier)
    rescue StandardError
      nil
    end
    set_page_metadata

    unless @product_grouping # If we fail to find grouping from perma, try treating it as a deprecated straight product permalink.
      @product = begin
        Product.active.find(grouping_identifier)
      rescue StandardError
        nil
      end
      redirect_route = store_product_path(product_grouping: @product.product_size_grouping_permalink, product: @product.permalink) if @product
      redirect_route ||= store_index_path # if we cant find this product, just go straight to store

      return redirect_to redirect_route
    end

    load_product_grouping_data
    bootstrap_store_data
    render :index
  end

  def show_cocktails
    set_page_metadata # TODO: we may need to change meta especially for cocktails in the future
    bootstrap_store_data
    render :index
  end

  # TODO: Do we need to handle cases where supplier is loaded and we want specific variant?
  # TODO: Do we need to handle cases where supplier is loaded and the product isn't available from current supplier?
  def show_product
    grouping_identifier = params[:product_grouping]
    product_identifier  = params[:product]

    @product_grouping = begin
      ProductSizeGrouping.includes(:view).active.find(grouping_identifier)
    rescue StandardError
      nil
    end
    set_page_metadata

    return redirect_to store_index_path unless @product_grouping

    # product is currently unused
    @product = begin
      Product.active.find(product_identifier)
    rescue StandardError
      nil
    end
    return redirect_to store_product_grouping_path(product_grouping: @product_grouping.permalink) if @product.nil? || @product.product_grouping_id != @product_grouping.id

    load_product_grouping_data
    bootstrap_store_data
    render :index
  end

  def show_cart_share
    bootstrap_store_data
    set_page_metadata

    render :index
  end

  def show_product_list
    bootstrap_store_data
    set_page_metadata

    render :index
  end

  private

  def bootstrap_store_data
    # TODO: clean this stuff out, the majority is being loaded via cookies
    load_supplier
    load_address
    check_show_content_while_loading
  end

  def load_supplier
    @supplier_ids = String(session_supplier).delete('"').split(',').map(&:to_i)
  end

  def load_address
    if @user && session_address
      address_matcher = { zip_code: session_address['zip_code'], address1: session_address['address1'] }
      @address = @user.shipping_addresses.active.find_by(address_matcher)
    end
    @address ||= create_shipping_address(session_address) if session_address
    @address_json = ConsumerAPIV2::Entities::ShippingAddress.new(@address, type: :has_coordinates).to_json if @address
  end

  def set_page_metadata
    @page_title = @product_grouping.nil? ? 'Wine, Liquor and Beer Delivered' : "#{@product_grouping.name} - Order Online - Minibar Delivery"
    @meta_description = @product_grouping.nil? ? nil : "Get #{@product_grouping.name} delivered. Order from Minibar Delivery, online or using our iPhone and Android apps."
  end

  def check_show_content_while_loading
    @show_content_while_loading = nil
    @show_content_while_loading = 'product' if @product_grouping
  end

  def load_product_grouping_data
    @product_grouping_data = @product_grouping.view.entity(exclude_variants: true, include_products: true).to_json
  end

  def check_load_font
    @load_font = !cookies[:fonts_loaded] || cookies[:fonts_loaded] != 'true'
  end

  def setup_test_store
    # these need to be manually set
    test_address = Address.find_by(address1: '560 Broadway')
    @address = create_shipping_address(test_address)
    @address_json = ConsumerAPIV2::Entities::ShippingAddress.new(@address, type: :has_coordinates).to_json if @address
    @supplier_ids = [1, 2] # TODO: make this a find? affects perf?
    cookies['sid'] = @supplier_ids.join(',').to_json

    # these can all be done normally
    load_user
  end

  def create_shipping_address(address)
    address ||= session_address
    Address.new(address1: address['address1'],
                address2: address['address2'],
                city: address['city'],
                state_name: address['state'] || address['state_name'],
                zip_code: address['zip_code'],
                latitude: address['latitude'],
                longitude: address['longitude'],
                address_purpose: :shipping)
  end
end
