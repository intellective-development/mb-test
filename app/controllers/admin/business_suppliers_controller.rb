class Admin::BusinessSuppliersController < Admin::BaseController
  before_action :load_supplier, only: %i[new create]
  before_action :load_business_supplier, only: %i[edit update toggle_status]

  def new
    @business_supplier = BusinessSupplier.new
  end

  def create
    @business_supplier = create_business_supplier.business_supplier

    if create_business_supplier.success?
      redirect_to edit_admin_inventory_supplier_path(@supplier)
    else
      flash[:error] = 'The business supplier could not be saved'
      render action: :new
    end
  end

  def update
    if update_business_supplier(business_supplier_params).success?
      redirect_to edit_admin_inventory_supplier_path(@business_supplier.supplier)
    else
      flash[:error] = 'The business supplier could not be updated'
      render action: :edit
    end
  end

  def toggle_status
    new_status = @business_supplier.active? ? 'inactive' : 'active'

    flash[:error] = 'The business supplier could not be updated' unless update_business_supplier({ status: new_status }).success?

    redirect_to edit_admin_inventory_supplier_path(@business_supplier.supplier)
  end

  private

  def create_business_supplier
    @create_business_supplier ||= ::BusinessSuppliers::Create.new(@supplier, business_supplier_params).call
  end

  def update_business_supplier(update_params)
    ::BusinessSuppliers::Update.new(@business_supplier, update_params).call
  end

  def load_supplier
    @supplier = Supplier.find(params[:supplier_id])
  end

  def load_business_supplier
    @business_supplier = BusinessSupplier.find(params[:id])
  end

  def business_supplier_params
    params.require(:business_supplier)
          .permit(:business_id, :percent_markup, :amount_markup, :score)
  end
end
