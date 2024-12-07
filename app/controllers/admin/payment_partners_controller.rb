# frozen_string_literal: true

class Admin::PaymentPartnersController < Admin::BaseController
  before_action :set_payment_partner, except: %i[index new create]

  def index
    @payment_partners = PaymentPartner.all
  end

  def new
    @payment_partner = PaymentPartner.new
  end

  def create
    @payment_partner = PaymentPartner.new(payment_partner_params)
    if @payment_partner.save
      redirect_to edit_admin_payment_partner_path(@payment_partner)
    else
      flash[:error] = 'The payment partner could not be saved'
      render action: :new
    end
  end

  def update
    if @payment_partner.update(payment_partner_params)
      redirect_to edit_admin_payment_partner_path(@payment_partner)
    else
      flash[:error] = 'The payment partner could not be updated'
      render action: :edit
    end
  end

  def destroy
    flash[:error] = 'The payment partner could not be deleted' unless @payment_partner.destroy
    redirect_to(action: :index)
  end

  private

  def payment_partner_params
    params.require(:payment_partner).permit(:name)
  end

  def set_payment_partner
    @payment_partner = PaymentPartner.find(params[:id])
  end
end
