class Admin::Fulfillment::OrderAdjustmentsController < Admin::Fulfillment::BaseController
  require 'data_cleaners'

  load_and_authorize_resource :shipment
  load_and_authorize_resource through: :shipment

  helper_method :order

  def new
    render :new, layout: false
  end

  def create
    @create_service = OrderAdjustmentCreationService.new(@shipment, order_adjustment_params)
    respond_to do |format|
      if @create_service.process!
        @order_adjustment = @create_service.records.first

        Segment::SendOrderUpdatedEventWorker.perform_async(@shipment.order.id, :order_adjustment_created)

        format.json { render json: @order_adjustment.to_json }
        format.html do
          @order_adjustment.order.touch # Because of the annoying conditional get
          notice = 'Order Adjustment Created.'
          notice << ' It will be processed as soon as the original payment is settled.' if @order_adjustment.waiting_for_settlement?
          redirect_to edit_admin_fulfillment_order_path(@shipment.order_number), notice: notice
        end
      else
        @order_adjustment = @create_service.error_record
        format.json { render json: @order_adjustment.errors.to_json }
        format.html { render action: 'new' }
      end
    end
  end

  private

  def order_adjustment_params
    params.require(:order_adjustment).permit(:reason_id, :description, :credit, :financial, :amount).merge!(
      user_id: current_user.id,
      braintree: true, # @shipment.braintree?,
      amount: DataCleaners::Parser::Price.parse(params[:order_adjustment][:amount])
    )
  end
end
