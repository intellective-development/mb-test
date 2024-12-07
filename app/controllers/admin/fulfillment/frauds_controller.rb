class Admin::Fulfillment::FraudsController < Admin::Fulfillment::BaseController
  before_action :load_order

  def create
    attrs = allowed_params.merge(user_id: current_user.id)
    attrs[:related_user_ids] = [] unless attrs[:related_user_ids]
    @order.fraud_record ? @order.fraud_record.update(attrs) : @order.create_fraud_record(attrs)
    redirect_to edit_admin_fulfillment_order_path(@order.id), error: 'Order has been flagged as fraud.'
  end

  private

  def allowed_params
    params.require(:fraudulent_order).permit(:payment_fraud_type, :cancel_account, :block_device, :chargeback_reported, related_user_ids: [])
  end

  def load_order
    @order = Order.find(params[:order_id])
  end
end
