class Admin::StorefrontRedirectionUrlsController < Admin::BaseController
  include GuestAuthenticable

  before_action :set_storefront
  before_action :set_storefront_redirection_url, except: %i[index new create]
  before_action :set_cart, :set_user, :set_address, only: %i[create update]
  before_action :process_order, only: [:create]

  def index
    @storefront_redirection_urls = StorefrontRedirectionUrl.where(storefront: @storefront).order(id: :desc)
  end

  def new
    @storefront_redirection_url = StorefrontRedirectionUrl.new
  end

  def create
    @storefront_redirection_url = StorefrontRedirectionUrl.new
    if @order.errors.empty? && @order.save
      @storefront_redirection_url.assign_attributes(
        value: build_redirection_endpoint, order: @order, name: storefront_redirection_url_params[:name],
        storefront: @storefront
      )
      if @storefront_redirection_url.save
        redirect_to(action: :index)
      else
        flash[:error] = 'The storefront redirection URL could not be saved'
        render action: :new
      end
    else
      flash[:error] = @order.errors.messages[:base].first
      render action: :new
    end
  end

  def destroy
    flash[:error] = 'The storefront redirection URL could not be deleted' unless @storefront_redirection_url.destroy
    redirect_to(action: :index)
  end

  private

  def process_order
    params_to_create_order = order_params
    params_to_create_order[:shipping_address_id] = @address.id

    @order = @user.orders.new(storefront: @storefront, cart: @cart)
    service = OrderCreationServices.new(
      @order, @user, @cart, params_to_create_order, skip_scheduling_check: true, skip_in_stock_check: @order.disable_in_stock_check?
    )
    return if service.build_order

    @order.errors.add(:base, service.error.message.split(' - ').last)
  end

  def build_redirection_endpoint
    base_url = @order.storefront.priority_hostname
    "https://#{base_url}/storefront/checkout?storefront_uuid=#{@order.storefront_uuid}&order_number=#{@order.number}"
  end

  def set_storefront
    @storefront = Storefront.find(params[:storefront_id])
  end

  def set_address
    @address = @user.addresses.active.find_by(id: params[:shipping_address_id])
    if @address.nil?
      @address = Address.find_by(id: order_params[:shipping_address_id]).dup
      @address.addressable = @user
      @address.save
    end
  end

  def set_cart
    @cart = Cart.find(params[:cart_id])
  end

  def set_user
    @user = User.find_by(id: order_params[:user_id]) || create_guest_user!(@storefront.id)
  end

  def set_storefront_redirection_url
    @storefront_redirection_url = StorefrontRedirectionUrl.find(params[:id])
  end

  def storefront_redirection_url_params
    params.require(:storefront_redirection_url).permit(:storefront_id, :name)
  end

  def order_params
    params.permit(
      :user_id, :shipping_address_id, :allow_substitution, :tip, :cart_id,
      gift_options: %i[recipient_name recipient_phone recipient_email message]
    )
  end
end
