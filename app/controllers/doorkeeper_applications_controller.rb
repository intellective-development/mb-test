class DoorkeeperApplicationsController < Doorkeeper::ApplicationsController
  def create
    @application = Doorkeeper.config.application_model.new(application_params)

    if @application.save
      update_storefront_application if params[:storefront_id].present?

      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications create])
      flash[:application_secret] = @application.plaintext_secret

      respond_to do |format|
        format.html { redirect_to oauth_application_url(@application) }
        format.json { render json: @application, as_owner: true }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json do
          errors = @application.errors.full_messages

          render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    if @application.update(application_params)
      update_storefront_application if params[:storefront_id].present?

      flash[:notice] = I18n.t(:notice, scope: i18n_scope(:update))

      respond_to do |format|
        format.html { redirect_to oauth_application_url(@application) }
        format.json { render json: @application, as_owner: true }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json do
          errors = @application.errors.full_messages

          render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def application_params
    params.require(:doorkeeper_application).permit(
      :name, :redirect_uri, :capture_defaults_on_authorization,
      :capture_payment_method_on_authorization, :allow_order_finalization, :skip_account_take_over_check,
      :storefront_id
    )
  end

  def update_storefront_application
    storefront = Storefront.find(params[:storefront_id])
    storefront.update!(oauth_application_id: @application.id)
  end
end
