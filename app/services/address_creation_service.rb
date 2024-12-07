class AddressCreationService
  include SentryNotifiable

  attr_reader :user, :doorkeeper_application, :address_params

  def initialize(user, doorkeeper_application, _options = {})
    @user = user
    @doorkeeper_application = doorkeeper_application

    raise AddressError, 'User is invalid' unless @user
  end

  def create(params)
    filtered_params(params)

    address_filters = address_params.merge(active: true)
    address_filters[:address2] = [nil, ''] if address_filters[:address2].blank?
    address = user.shipping_addresses.where(address_filters.except(:geocoded_at)).first || user.addresses.new(address_params)
    address.city = address.zip_code.to_region(city: true) if address.city.blank?
    address.save!
    address
  rescue StandardError => e
    notify_sentry_and_log(e, "[Address creation] #{e.message} for user #{user.id} \n #{params} \n #{address_params}")
    false
  end

  # Used in instances where the user only provides their billing zip code.
  def create_billing_address(name, zip_code)
    address = user.billing_addresses.new(name: name, address1: 'Not Provided', city: zip_code.to_region(city: true) || 'Unknown', state_name: zip_code.to_region(state: true), zip_code: zip_code,
                                         doorkeeper_application: doorkeeper_application)
    address.save!
    address
  rescue StandardError => e
    notify_sentry_and_log(e)
    false
  end

  private

  def filtered_params(params)
    params[:state_name] = params[:state] if params[:state].present?
    params[:city] = params[:city].split(',').first if params[:city].present?
    params[:name] = user.name if params[:name].blank?
    params[:doorkeeper_application_id] = doorkeeper_application.id if doorkeeper_application
    params[:address_purpose] = 0 if params[:address_purpose].blank?
    params[:geocoded_at] = Time.zone.now if params[:latitude].present? && params[:longitude].present?

    @address_params = permitted_params(params)
  end

  def permitted_params(params)
    ActionController::Parameters.new(params.to_h.compact).permit(:name, :address1, :address2, :city, :state_name, :zip_code, :company, :latitude, :longitude, :geocoded_at,
                                                                 :phone, :default, :billing_default, :active, :doorkeeper_application_id, :address_purpose)
  end
end

class AddressError < StandardError
  attr_reader :status, :detail

  def initialize(body, options = {})
    @status = options.delete(:status) || 500
    @detail = options
    @detail[:message] = body
    @detail[:name] ||= 'AddressError'
  end

  def to_s
    "#{@detail[:name]}: #{@detail[:message]}"
  end
end
