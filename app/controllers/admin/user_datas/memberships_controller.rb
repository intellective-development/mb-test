class Admin::UserDatas::MembershipsController < Admin::BaseController
  helper_method :sort_column, :sort_direction
  before_action :load_membership, only: %i[edit update cancel refund]

  def index
    @memberships = list_membership.result
  end

  def new
    @membership = Membership.new
  end

  def create
    if create_membership.success?
      redirect_to action: :index
    else
      @membership = create_membership.membership

      flash[:error] = 'The membership could not be saved'
      render action: :new
    end
  end

  def edit
    @orders = Order::List.new(params.merge({ membership_id: params[:id] })).call.result
    @transactions = @membership.transactions
  end

  def cancel
    flash[:error] = 'The membership could not be canceled!' unless cancel_membership.success?

    redirect_to action: :index
  end

  def refund
    flash[:error] = 'The membership could not be refunded!' unless refund_membership.success?

    redirect_to action: :index
  end

  private

  def create_membership
    membership_params = params[:membership]

    user = User.find(membership_params[:user_id])
    storefront = Storefront.find(membership_params[:storefront_id])
    payment_profile = PaymentProfile.find(membership_params[:payment_profile_id])

    ::Memberships::Create.new(storefront: storefront, user: user, payment_profile: payment_profile).call
  end

  def cancel_membership
    @cancel_membership = ::Memberships::Cancel.new(membership: @membership).call
  end

  def refund_membership
    @refund_membership = ::Memberships::Refund.new(membership: @membership, user: current_user, refund_tax: true).call
  end

  def list_membership
    @list_membership = ::Memberships::List.new(params).call
  end

  def load_membership
    @membership = Membership.find(params[:id])
  end

  def sort_column
    if %w[edit update].include? params[:action]
      return Order.column_names.include?(params[:sort]) ? params[:sort] : 'completed_at'
    end

    Membership.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
