class Account::AddressesController < Account::BaseController
  helper_method :countries
  layout 'minibar'

  def index
    @addresses = current_user.shipping_addresses.active.order(updated_at: :desc)
  end

  def new
    form_info
    @address = Address.new
    @address.country = countries.first if !Settings.require_state_in_address && countries.size == 1
    @address.default = true if current_user.default_shipping_address.nil?
    @form_address = @address
  end

  def create
    @address = current_user.addresses.new(allowed_params)
    @address.default = true          if current_user.default_shipping_address.nil?
    @address.billing_default = true  if current_user.default_billing_address.nil?

    respond_to do |format|
      if @address.save
        format.html { redirect_to(account_address_url(@address), notice: 'Address was successfully created.') }
      else
        @form_address = @address
        form_info
        format.html { render action: 'new' }
      end
    end
  end

  def edit
    form_info
    @form_address = @address = current_user.addresses.find(params[:id])
  end

  # This is not normal because you should never Update an address.
  # The address could point to an existing order which needs to keep the same address
  def update
    @address = current_user.addresses.new(allowed_params)
    @address.replace_address_id = params[:id] # This makes the address we are updating inactive if we save successfully

    # if we are editing the current default address then this is the default address
    @address.default         = true if params[:id].to_i == current_user.default_shipping_address.try(:id)
    @address.billing_default = true if params[:id].to_i == current_user.default_billing_address.try(:id)

    respond_to do |format|
      if @address.save
        delete_address_cookie if Integer(params[:id]) == current_address_id

        format.html { redirect_to account_addresses_path }
      else
        # the form needs to have an id
        @form_address = current_user.addresses.find(params[:id])
        # the form needs to reflect the attributes to customer entered
        @form_address.attributes = allowed_params
        form_info
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @address = current_user.addresses.find(params[:id])
    @address.deactivate

    delete_address_cookie if Integer(params[:id]) == current_address_id

    flash[:notice] = 'Successfully removed address.'
    redirect_to account_addresses_url
  end

  private

  def allowed_params
    params.require(:address).permit(:name, :company, :address1,
                                    :address2, :city, :state_id, :state_name,
                                    :zip_code, :default, :billing_default,
                                    :country_id, :address_purpose)
  end

  def current_address_id
    Integer(JSON.parse(cookies[:address])['id'])
  rescue StandardError
    nil
  end

  def delete_address_cookie
    cookies.delete :address
  end

  def form_info
    @states = State.form_selector
  end

  def countries
    @countries ||= Country.active
  end
end
