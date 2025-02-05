class Admin::Fulfillment::Partial::ShipmentsController < Admin::Fulfillment::BaseController
  def create
    @order = Order.find_by(number: params[:order_id])
    if @order.create_shipments_with_order_item_ids(params[:order_item_ids])
      redirect_to edit_admin_fulfillment_order_url(@order), notice: 'Successfully created shipment.'
    else
      form_info
      flash[:alert] = 'There was an issue creating the shipment.'
      render :new
    end
  end

  def new
    @order = Order.includes(order_items: { variant: :product }).find_by(number: params[:order_id])
  end

  def update
    @order = Order.find_by(number: params[:order_id])
    if @order.create_shipments_with_order_item_ids(params[:order][:order_item_ids])
      redirect_to edit_admin_fulfillment_order_url(@order), notice: 'Successfully created shipment.'
    else
      form_info
      flash[:alert] = 'There was an issue creating the shipment.'
      render :new
    end
  end

  private

  def form_info; end
end
