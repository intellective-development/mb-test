class Admin::Config::OrderAdjustmentReasonsController < Admin::Config::BaseController
  def index
    @reasons = ::OrderAdjustmentReasons::List.new(params).call.result
  end

  def new
    @reason = OrderAdjustmentReason.new
  end

  def edit
    @reason = OrderAdjustmentReason.find(params[:id])
  end

  def create
    @reason = OrderAdjustmentReason.new(allowed_params)

    if @reason.save
      redirect_to(admin_config_order_adjustment_reasons_url, notice: 'Reason was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    @reason = OrderAdjustmentReason.find(params[:id])

    if @reason.update(allowed_params)
      redirect_to(admin_config_order_adjustment_reasons_url, notice: 'Reason was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def allowed_params
    params.require(:order_adjustment_reason)
          .permit(:name,
                  :description,
                  :customer_facing_name,
                  :invoice_display_name,
                  :owed_to_minibar,
                  :owed_to_supplier,
                  :cancel,
                  :order_adjustment,
                  :marketing_fee_adjustment,
                  :active,
                  :reporting_type)
  end
end
