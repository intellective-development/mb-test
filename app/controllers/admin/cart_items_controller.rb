class Admin::CartItemsController < Admin::BaseController
  before_action :set_cart
  before_action :set_cart_item, except: %i[index new create]

  def index
    @cart_items = CartItem.all
  end

  def new
    @cart_item = CartItem.new
  end

  def create
    @cart_item = CartItem.new(cart_item_params)
    if @cart_item.save
      redirect_to edit_admin_cart_path(@cart)
    else
      flash[:error] = 'The Cart Item could not be saved'
      render action: :new
    end
  end

  def update
    if @cart_item.update(cart_item_params)
      redirect_to edit_admin_cart_path(@cart)
    else
      flash[:error] = 'The Cart Item could not be updated'
      render action: :edit
    end
  end

  def destroy
    flash[:error] = 'The Cart Item could not be deleted' unless @cart_item.destroy
    redirect_to edit_admin_cart_path(@cart)
  end

  private

  def item_options
    return @item_options if defined?(@item_options)

    @item_options = case params[:type]
                    when ''
                      nil
                    when '1'
                      GiftCardOptions.new(gift_card_options_params)
                    when '2'
                      EngravingOptions.new(engraving_options_params)
                    end
  end

  def set_cart
    @cart = Cart.find(params[:cart_id])
  end

  def set_cart_item
    @cart_item = CartItem.find(params[:id] || params[:cart_item_id])
  end

  def engraving_options_params
    params[:cart_item].require(:item_options).permit(
      :line1, :line2, :line3, :line4
    )
  end

  def gift_card_options_params
    params[:cart_item].require(:item_options).permit(
      :sender, :message, :send_date, :price,
      :gift_card_image_id, { recipients: [] }
    )
  end

  def cart_item_params
    params.require(:cart_item).permit(
      :cart_id, :quantity, :product_bundle_id, :variant_id,
      :customer_placement
    ).merge(default_params)
  end

  def default_params
    variant_id = params[:cart_item][:variant_id]
    type = params[:type]
    {
      item_options: item_options,
      item_type_id: ItemType::SHOPPING_CART_ID,
      identifier: CartItem.generate_identifier(item_options, type, variant_id)
    }
  end
end
