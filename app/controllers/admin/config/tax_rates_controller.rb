class Admin::Config::TaxRatesController < Admin::Config::BaseController
  helper_method :countries

  # GET /admin/config/tax_rates
  def index
    @tax_rates = TaxRate.admin_grid(params)
                        .page(params[:page] || 1)
                        .per(params[:per] || 25)
  end

  # GET /admin/config/tax_rates/1
  def show
    @tax_rate = TaxRate.find(params[:id])
  end

  # GET /admin/config/tax_rates/new
  def new
    @tax_rate = TaxRate.new
    form_info
  end

  # GET /admin/config/tax_rates/1/edit
  def edit
    @tax_rate = TaxRate.find(params[:id])
    form_info
  end

  # POST /admin/config/tax_rates
  def create
    @tax_rate = TaxRate.new(allowed_params)

    if @tax_rate.save
      redirect_to(admin_config_tax_rate_url(@tax_rate), notice: 'Tax rate was successfully created.')
    else
      form_info
      render action: :new
    end
  end

  # PUT /admin/config/tax_rates/1
  def update
    @tax_rate = TaxRate.find(params[:id])

    if @tax_rate.update(allowed_params)
      redirect_to(admin_config_tax_rate_url(@tax_rate), notice: 'Tax rate was successfully updated.')
    else
      form_info
      render action: :edit
    end
  end

  def expire
    @tax_rate = TaxRate.find(params[:tax_rate_id])
    @tax_rate.expire!
    redirect_to(admin_config_tax_rates_url)
  end

  # DELETE /admin/config/tax_rates/1
  def destroy
    @tax_rate = TaxRate.find(params[:id])
    @tax_rate.inactivate!
    redirect_to(admin_config_tax_rates_url)
  end

  private

  def allowed_params
    params.require(:tax_rate).permit(:percentage, :zipcode, :state_id, :country_id, :start_date,
                                     :end_date, :active, :tax_category_id)
  end

  def countries
    @countries ||= Country.form_selector
  end

  def form_info
    @select_tax_category = TaxCategory.all.collect { |tc| [tc.name, tc.id] }
    @select_state_id     = State.all.collect { |s| [s.name, s.id] }
  end
end
