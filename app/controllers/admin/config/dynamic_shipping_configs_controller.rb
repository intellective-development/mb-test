class Admin::Config::DynamicShippingConfigsController < Admin::Config::BaseController
  before_action :set_dynamic_shipping_config, only: %i[edit update]

  def edit; end

  def update
    if @dynamic_shipping_config.update(dynamic_shipping_config_params)
      redirect_to edit_admin_config_dynamic_shipping_config_url(@dynamic_shipping_config),
                  notice: 'Dynamic shipping config was successfully updated.'
    else
      render :edit
    end
  end

  private

  def set_dynamic_shipping_config
    @dynamic_shipping_config = DynamicShippingConfig.first_or_create!
  end

  def dynamic_shipping_config_params
    params.require(:dynamic_shipping_config)
          .permit(:fuel_surcharge,
                  :adult_signature_surcharge,
                  :residential_delivery_surcharge,
                  :holiday_surcharge,
                  :heavy_fee)
  end
end
