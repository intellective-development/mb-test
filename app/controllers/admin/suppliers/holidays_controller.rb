class Admin::Suppliers::HolidaysController < Admin::BaseController
  before_action :load_suppliers, only: %i[new edit]

  def index
    @holidays = Holiday.includes(:user, supplier_holidays: [:supplier])
                       .admin_grid(params)
                       .upcoming_all
                       .order(:date)
                       .page(params[:page] || 1)
                       .per(20)

    @breaks = DeliveryBreak.upcoming
                           .order(:date)
                           .page(params[:page] || 1)
                           .per(20)

    @external_breaks = Supplier.where(external_availability: false)
                               .order(:name)
                               .page(params[:page] || 1)
                               .per(20)

    # use single paginator for all (biggest one)
    @paginator = @holidays
    @paginator = @breaks if @breaks.total_pages > @paginator.total_pages
    @paginator = @external_breaks if @external_breaks.total_pages > @paginator.total_pages
  end

  def new
    @holiday = Holiday.new
  end

  def create
    start_date = holiday_params['start_date']
    end_date = holiday_params['end_date']
    (Date.parse(start_date)..Date.parse(end_date)).to_a.each do |date|
      @holiday = Holiday.new(holiday_params)
      @holiday.user = current_user
      @holiday.date = date.strftime('%m/%d/%Y')
      return render action: :new unless @holiday.save
    end
    redirect_to admin_suppliers_holidays_path, notice: "A new holiday has been created from #{start_date} to #{end_date}"
  end

  def edit
    @holiday = Holiday.find(params[:id])
  end

  def update
    @holiday = Holiday.find(params[:id])
    if @holiday.update(holiday_params)
      redirect_to admin_suppliers_holidays_path, notice: 'Holiday Updated'
    else
      render action: :edit
    end
  end

  def destroy
    @holiday = Holiday.find(params[:id])
    @holiday.destroy

    redirect_to admin_suppliers_holidays_path, notice: 'Successfully deleted holiday.'
  end

  def destroy_supplier_break
    @break = DeliveryBreak.find(params[:holiday_id])
    @break.destroy

    redirect_to admin_suppliers_holidays_path, notice: 'Successfully deleted break.'
  end

  private

  def suppliers
    suppliers = Supplier.where(id: params[:holiday][:supplier_ids].split(','))
  end

  def holiday_params
    data = params.require(:holiday).permit(:date, :start_date, :end_date, shipping_types: [])
    data[:shipping_types] = data[:shipping_types].reject(&:empty?) if data[:shipping_types].present?
    data[:suppliers] = suppliers unless suppliers.empty?

    data
  end

  def load_suppliers
    @suppliers = Supplier.active.order(:name).pluck(:name, :id)
  end
end
