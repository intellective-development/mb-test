class Admin::Fulfillment::Orders::ShipmentsController < Admin::Fulfillment::BaseController
  before_action :load_order, :load_shipment, only: %i[update_supplier_for_pre_sale update_supplier_for_pre_sale_dialogue]

  def update_supplier_for_pre_sale_dialogue
    render :update_supplier_for_pre_sale_dialogue, layout: false
  end

  def update_supplier_for_pre_sale
    new_supplier = Supplier.find(allowed_params[:supplier_id])

    unless @shipment.pre_sale_eligible_for_supplier_switching?(new_supplier)
      flash['error'] = 'Shipment or supplier not eligible for switching'
      redirect_to edit_admin_fulfillment_order_path(@order.number) and return
    end

    PreSales::SwitchSupplierWorker.perform_async(@shipment.id, new_supplier.id, current_user.id)

    flash[:notice] = "Shipment's supplier update request will be processed."
    redirect_to edit_admin_fulfillment_order_path(@order.number)
  end

  private

  def load_order
    @order = Order.find(params[:order_id])
  end

  def load_shipment
    @shipment = @order.shipments.find(params[:id])
  end

  def allowed_params
    params.permit(:supplier_id)
  end
end
