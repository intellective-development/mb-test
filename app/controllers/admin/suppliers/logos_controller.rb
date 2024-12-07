class Admin::Suppliers::LogosController < Admin::BaseController
  before_action :load_suppliers, only: %i[new edit]

  def index
    @logos = Logo.includes(:user, supplier_logos: [:supplier])
                 .admin_grid(params)
                 .page(params[:page] || 1)
                 .per(20)

    @paginator = @logos
  end

  def new
    @logo = Logo.new
  end

  def create
    @logo = Logo.new(logo_params)
    @logo.user = current_user

    if @logo.save
      @logo.suppliers = suppliers
      redirect_to admin_suppliers_logos_path, notice: 'Logo Created'
    else
      render action: :new
    end
  end

  def edit
    @logo = Logo.find(params[:id])
  end

  def update
    @logo = Logo.find(params[:id])
    if @logo.update(logo_params)
      @logo.suppliers = suppliers unless suppliers.empty?
      redirect_to admin_suppliers_logos_path, notice: 'Logo Updated'
    else
      render action: :edit
    end
  end

  def destroy
    @logo = Logo.find(params[:id])
    @logo.destroy

    redirect_to admin_suppliers_logos_path, notice: 'Successfully deleted logo.'
  end

  private

  def suppliers
    suppliers = Supplier.where(id: params[:logo][:supplier_ids].split(','))
  end

  def logo_params
    params.require(:logo).permit(:image)
  end

  def load_suppliers
    @suppliers = Supplier.active.order(:name).pluck(:name, :id)
  end
end
