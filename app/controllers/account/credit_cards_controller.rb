class Account::CreditCardsController < Account::BaseController
  layout 'minibar'

  def index
    @credit_cards = current_user.payment_profiles.active.order(updated_at: :desc)
  end

  def show
    @credit_card = current_user.payment_profiles.find(params[:id])
  end

  def new
    @credit_card = current_user.payment_profiles.new
  end

  def create
    @credit_card = current_user.payment_profiles.new(allowed_params)
    if @credit_card.save
      flash[:notice] = 'Successfully created credit card.'
      redirect_to account_credit_card_url(@credit_card)
    else
      render action: 'new'
    end
  end

  def edit
    @credit_card = current_user.payment_profiles.find(params[:id])
  end

  def update
    @credit_card = current_user.payment_profiles.find(params[:id])
    if @credit_card.update(allowed_params)
      flash[:notice] = 'Successfully updated credit card.'
      redirect_to account_credit_card_url(@credit_card)
    else
      render action: 'edit'
    end
  end

  def destroy
    @credit_card = current_user.payment_profiles.find(params[:id])
    @credit_card.deactivate
    flash[:notice] = 'Successfully removed credit card.'
    redirect_to account_credit_cards_url
  end

  private

  def allowed_params
    params.require(:credit_card).permit(:address_id, :month, :year, :cc_type,
                                        :first_name, :last_name, :card_name)
  end
end
