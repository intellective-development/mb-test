class Admin::UserDatas::AddressesController < Admin::BaseController
  skip_before_action :verify_authenticity_token

  def update
    @address = Address.find(params[:id])
    @address.assign_attributes(allowed_params)
    @address.validate_for_ongoing_orders

    respond_to do |format|
      if @address.errors.empty? && @address.save
        flash[:notice] = 'Successfully updated shipping address.'
        # update address in order invoices
        ShipmentAddressUpdateWorker.perform_async(@address.id, current_user.id)
      else
        flash[:alert] = ['Failed to update shipping address.'].concat(@address.errors.map(&:message)).join('. ')
      end
      format.html { redirect_to admin_customer_path(params[:user_id]) }
    end
  end

  private

  def allowed_params
    params.require(:address).permit(:name, :address1, :address2, :phone, :city, :state_name, :zip_code)
  end
end
