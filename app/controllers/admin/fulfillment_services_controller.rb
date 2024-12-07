class Admin::FulfillmentServicesController < Admin::BaseController
  delegate      :sort_column, :sort_direction, to: :list_fulfillment_services
  helper_method :sort_column, :sort_direction

  before_action :load_fulfillment_service, only: %i[edit update toggle_status]

  def index
    @fulfillment_services = list_fulfillment_services.result
  end

  def new
    @fulfillment_service = FulfillmentService.new
  end

  def create
    @fulfillment_service = create_fulfillment_service.fulfillment_service

    if create_fulfillment_service.success?
      redirect_to action: :index
    else
      flash[:error] = 'The fulfillment service could not be saved'
      render action: :new
    end
  end

  def update
    if update_fulfillment_service(fulfillment_service_params).success?
      redirect_to action: :index
    else
      flash[:error] = 'The fulfillment service could not be updated'
      render action: :edit
    end
  end

  def toggle_status
    new_status = @fulfillment_service.active? ? 'inactive' : 'active'

    if update_fulfillment_service({ status: new_status }).success?
      redirect_to action: :index
    else
      flash[:error] = 'The fulfillment service could not be updated'
      render action: :index
    end
  end

  private

  def list_fulfillment_services
    @list_fulfillment_services ||= ::FulfillmentServices::List.new(params).call
  end

  def create_fulfillment_service
    @create_fulfillment_service ||= ::FulfillmentServices::Create.new(fulfillment_service_params).call
  end

  def update_fulfillment_service(update_params)
    ::FulfillmentServices::Update.new(@fulfillment_service, update_params).call
  end

  def load_fulfillment_service
    @fulfillment_service = FulfillmentService.find(params[:id])
  end

  def fulfillment_service_params
    params.require(:fulfillment_service).permit(:name, :pim_name, :supplier_modifiable)
  end
end
