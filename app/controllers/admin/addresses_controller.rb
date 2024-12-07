class Admin::AddressesController < Admin::BaseController
  before_action :set_address, except: %i[index new create]

  def index
    @addresses = current_user.addresses
  end

  def new
    @address = Address.new
  end

  def create
    @address = Address.new(address_params)
    if @address.save
      redirect_to(action: :index)
    else
      flash[:error] = 'The address could not be saved'
      render action: :new
    end
  end

  def update
    if @address.update(address_params)
      redirect_to(action: :index)
    else
      flash[:error] = 'The address could not be updated'
      render action: :edit
    end
  end

  def destroy
    flash[:error] = 'The address could not be deleted' unless @address.destroy
    redirect_to(action: :index)
  end

  private

  def address_params
    params.require(:address)
          .permit(:name, :address1, :zip_code, :city, :address_purpose)
          .merge(addressable: current_user)
  end

  def set_address
    @address = Address.find(params[:id])
  end
end
