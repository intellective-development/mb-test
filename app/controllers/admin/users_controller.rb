class Admin::UsersController < Admin::BaseController
  include Admin::UserHelper

  def index
    authorize! :view_users, current_user

    if params[:search].present? || params[:phone].present?
      search_terms = params[:search].to_s
      search_terms += " #{params[:phone].to_s.gsub(/\D/, '')}"
      @users = User.search(search_terms, includes: [:account], page: pagination_page, per_page: pagination_rows)
    else
      @users = User.admin_grid(params)
                   .includes(account: [:storefront])
                   .order(id: :desc)
                   .page(pagination_page)
                   .per(pagination_rows)
    end

    expires_in 5.minutes, public: false
  end

  def show
    @user = User.includes(:profile, :shipping_addresses, payment_profiles: [:address]).find_by(id: params[:id]) || User.includes(:profile).find_by(referral_code: params[:id])

    expires_in 1.hour, public: false
    respond_to(&:html) if stale?(etag: @user, last_modified: @user.updated_at)
  end

  def new
    @user = User.new
    @supplier_id = @user.supplier.try(:id)
    authorize! :create_users, current_user
    form_info
  end

  def create
    @user = User.new(user_params)
    @user.format_birth_date(params[:user][:birth_date]) if params[:user][:birth_date].present?
    @user.account.storefront_id = Storefront::MINIBAR_ID # This UI could only be used to create minibar Users
    authorize! :create_users, current_user

    if @user.save
      @user.employee_of_supplier(params[:supplier][:supplier_id]) if params[:supplier].present?

      flash[:notice] = 'Your account has been created. Please check your e-mail for your account activation instructions!'
      redirect_to admin_customers_url
    else
      form_info
      render action: :new
    end
  end

  def edit
    @user = User.includes(:account).find(params[:id])
    @supplier_id = @user.supplier.try(:id)
    authorize! :create_users, current_user
    form_info
  end

  def update
    @user = User.includes(:account).find(params[:id])
    authorize! :create_users, current_user

    @user.format_birth_date(params[:user][:birth_date]) if params[:user][:birth_date].present?
    @user.account.cancel if user_params[:account_attributes][:state].presence == 'canceled'

    # [TECH-2557] If guest account email was not updated
    update_params = user_params.clone

    # [TECH-5184] Validate if company name was entered without the corporate checkbox
    if update_params[:corporate] == '0' && !update_params[:company_name].empty?
      flash[:notice] = 'Company name entered but customer is not marked as corporate'
      form_info
      render action: :edit
      return
    end

    # avoid updating email for guest users and avoid setting contact_email for non guest users
    if @user.account.guest?
      update_params[:account_attributes][:contact_email] = user_params[:account_attributes][:email]
      update_params[:account_attributes][:email] = @user.account.read_attribute(:email)
    end

    # Keep the credentials_admin role since we can't select it on the FE
    if @user.roles.include?(:credentials_admin)
      update_params[:roles] ||= []
      update_params[:roles] << :credentials_admin
    end

    if current_user.roles.exclude?(:credentials_admin)
      update_params[:roles] ||= []
      # TECH-7228 Admin, SuperAdmin and CustomerService can only give supplier and driver permission
      update_params[:roles].select! { |role| %i[supplier driver].include?(role.to_sym) }
      # Keep previous roles, since some users can't select them on the FE
      update_params[:roles] += @user.roles.to_a.select { |role| %i[supplier driver].exclude?(role.to_sym) }
    end

    if @user.update(update_params)
      @user.employee_of_supplier(params[:supplier][:supplier_id]) if params[:supplier].present?

      if params[:brand_id].present?
        brand = Brand.find(params[:brand_id])
        @user.brand_content_manager ? @user.brand_content_manager.update(brand: brand) : @user.create_brand_content_manager(brand: brand)
      end

      flash[:notice] = "#{@user.name} has been updated."
      redirect_to admin_customers_url
    else
      @user = User.includes(:account).find(params[:id])
      @supplier_id = @user.supplier.try(:id)
      authorize! :create_users, current_user
      form_info
      render action: :edit
    end
  end

  def comments
    @user = User.includes(:comments).find(params[:id])
    @comments = @user.comments.order(created_at: :desc)
  end

  # TODO: Put these methods out of their misery. Perhaps replace with: https://github.com/ankane/pretender
  def su
    return unless current_user.admin?

    session[:su_user] = current_user.id
    @user = User.includes(:account).find(params[:id])
    warden.set_user(@user.account, bypass: true)
    set_cookies
    flash[:notice] = "You've switched to #{@user.name}'s account."
    redirect_to ENV['WEB_STORE_URL'] || root_path
  end

  def unsu
    if session.key?(:su_user)
      @user = User.find session[:su_user]
      unless @user.admin?
        flash[:error] = 'Sorry, something went wrong with your original user.'
        redirect_to login_path
      end
      assumed_user_id = current_user.id
      warden.set_user(@user.account, bypass: true)
      remove_cookies
      flash[:notice] = 'You have exited your su session. You are now yourself.'
      redirect_to admin_customer_path(assumed_user_id)
    else
      flash[:error] = "Sorry, we couldn't find your original user."
      redirect_to ENV['WEB_STORE_URL'] || root_path
    end
  end

  def password_reset
    @user = User.find(params[:id])
    if @user && @user.email.present? # Actually check the delegated user.
      @user.account.send_reset_password_instructions
      flash[:notice] = "Instructions to reset #{@user.name}'s password have been emailed."
      redirect_to admin_customer_url(@user.id)
    else
      flash[:notice] = 'User or email not found.'
      redirect_to admin_customers_url
    end
  end

  def clear_ato
    @user = User.find(params[:id])
    if @user
      options = {
        type: 'account_recovered',
        source: 'manual_review',
        analyst: current_user.email,
        user_id: @user.id.to_s,
        time: Time.now
      }
      response = Fraud::Decision.new(options).call
      if response&.ok?
        SessionVerificationService.reset_ato_email_count(@user)
        flash[:notice] = "#{@user.name}'s ATO has been reset."
      else
        flash[:alert] = "Error reseting user's ATO: #{response&.body&.description}."
      end
      redirect_to admin_customer_url(@user.id)
    else
      flash[:notice] = 'User not found.'
      redirect_to admin_customers_url
    end
  end

  def ato_email_count_reset
    @user = User.find(params[:id])
    if @user
      SessionVerificationService.reset_ato_email_count(@user)
      flash[:notice] = "#{@user.name}'s count of emails for account verification has been reset."
      redirect_to admin_customer_url(@user.id)
    else
      flash[:notice] = 'User not found.'
      redirect_to admin_customers_url
    end
  end

  def anonymize
    @user = User.find(params[:id])
    if @user
      @user.anonymize
      flash[:notice] = "#{@user.name}'s has been anonymized."
      redirect_to admin_customer_url(@user.id)
    else
      flash[:notice] = 'User not found.'
      redirect_to admin_customers_url
    end
  end

  def demote_admin_access
    if @current_user.credentials_admin?
      user = User.find(params[:id])

      roles = user.roles.reject { |role| User::ADMIN_LIKE_ROLES.include?(role) || role == :credentials_admin }
      user.update!(roles: roles)

      flash[:notice] = "Admin #{user.name}'s was demoted."
    else
      flash[:notice] = 'You don\'t have permission!'
    end

    redirect_to admin_customers_url
  end

  private

  def set_cookies
    application = Doorkeeper::Application.find_by(uid: ENV['WEB_STORE_CLIENT_ID'], secret: ENV['WEB_STORE_CLIENT_SECRET'])
    expires_in = Doorkeeper.configuration.access_token_expires_in
    access_token = Doorkeeper::AccessToken.find_or_create_for(
      application: application,
      resource_owner: @user.account.id,
      scopes: Doorkeeper::OAuth::Scopes.from_array([]),
      expires_in: expires_in,
      use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
    )
    domain = Rails.env.production? ? '.minibardelivery.com' : nil
    cookies.delete(:cart_id, { domain: domain, path: '/' })
    cookies.delete(:promo, { domain: domain, path: '/' })
    cookies[:access_token] = {
      value: { token_type: 'bearer', expires_in: expires_in, access_token: access_token.token }.to_json,
      domain: domain,
      path: '/'
    }
    cookies[:su] = {
      value: true,
      domain: domain,
      path: '/'
    }
  end

  def remove_cookies
    domain = Rails.env.production? ? '.minibardelivery.com' : nil
    cookies.delete(:access_token, { domain: domain, path: '/' })
    cookies.delete(:su, { domain: domain, path: '/' })
    cookies.delete(:cart_id, { domain: domain, path: '/' })
    cookies.delete(:promo, { domain: domain, path: '/' })
  end

  def user_params
    params.require(:user).permit(:supplier_id, :vip, :corporate, :tax_exempt, :company_name, :form_birth_date, :tax_exemption_code,
                                 account_attributes: %i[password password_confirmation first_name last_name email contact_email state storefront_id],
                                 roles: [])
  end

  def form_info
    @states = %w[active canceled]
    @tax_exemption_codes = User.enum_to_human_key_value_pair(:tax_exemption_code, User.tax_exemption_codes)
  end
end
