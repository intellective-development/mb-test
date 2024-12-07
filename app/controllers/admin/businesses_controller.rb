class Admin::BusinessesController < Admin::BaseController
  helper_method :sort_column, :sort_direction
  delegate      :sort_column, :sort_direction, to: :list_business

  before_action :load_business, only: %i[edit update]
  def index
    @businesses = list_business.result
  end

  def new
    @business = Business.new
  end

  def create
    @business = create_business.business

    if create_business.success?
      redirect_to action: :index
    else
      flash[:error] = 'The business could not be saved'
      render action: :new
    end
  end

  def update
    if update_business.success?
      redirect_to action: :index
    else
      flash[:error] = 'The fulfillment service could not be updated'
      render action: :edit
    end
  end

  private

  def load_business
    @business = Business.find(params[:id])
  end

  def list_business
    @list_business = ::Businesses::List.new(params).call
  end

  def create_business
    @create_business ||= ::Businesses::Create.new(business_params).call
  end

  def update_business
    ::Businesses::Update.new(@business, business_params).call
  end

  def business_params
    optional_attributes = %i[name
                             service_fee
                             price_rounding
                             video_gift_fee
                             fee_supplier_permalink
                             product_supplier_permalink
                             avalara_company_code
                             bevmax_partner_name
                             bevmax_account_id
                             bevmax_channel_id]

    if current_user.credentials_admin?
      optional_attributes += %i[braintree_cse_key
                                braintree_merchant_id
                                braintree_private_key
                                braintree_public_key
                                braintree_tokenization_key]
    end

    params.require(:business).permit(optional_attributes)
  end
end
