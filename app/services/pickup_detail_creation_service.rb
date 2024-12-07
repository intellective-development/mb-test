class PickupDetailCreationService
  include SentryNotifiable

  attr_reader :user, :doorkeeper_application, :pickup_detail_params

  def initialize(user, doorkeeper_application, _options = {})
    @user = user
    @doorkeeper_application = doorkeeper_application

    raise PickupDetailError, 'User is invalid' unless @user
  end

  def create(params)
    filtered_params(params)

    pickup_details = user.pickup_details.where(pickup_detail_params).first || user.pickup_details.new(pickup_detail_params)
    pickup_details.save!
    pickup_details
  rescue StandardError => e
    notify_sentry_and_log(e)
    false
  end

  private

  def filtered_params(params)
    params[:doorkeeper_application_id] = doorkeeper_application.id if doorkeeper_application

    @pickup_detail_params = permitted_params(params)
  end

  def permitted_params(params)
    params = ActionController::Parameters.new(params) unless params.instance_of?(ActionController::Parameters)

    params.permit(:name, :phone, :doorkeeper_application_id)
  end
end

class PickupDetailError < StandardError
  attr_reader :status, :detail

  def initialize(body, options = {})
    @status = options.delete(:status) || 500
    @detail = options
    @detail[:message] = body
    @detail[:name] ||= 'PickupDetailError'
  end

  def to_s
    "#{@detail[:name]}: #{@detail[:message]}"
  end
end
