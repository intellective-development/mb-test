class ConsumerAPIV2::WaitlistEndpoint < BaseAPIV2
  format :json
  content_type :txt, 'text/plain'

  before do
    unless params[:storefront_id].nil?
      @storefront = Storefront.find_by(id: params[:storefront_id])
      error!('Storefront not found', 404) if @storefront.nil?
    end
  end

  desc 'Adds email address to the zipcode waitlist', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    requires :email, type: String, desc: 'Email address of a user', regexp: CustomValidators::Emails.email_validator
    optional :zip_code, type: String, desc: 'Zip code', regexp: /[0-9]{5}/, default: '00000'
    optional :apn_token, type: String, desc: 'Push Notification Token'
    optional :one_signal_id, type: String, desc: 'Push Notification Token'
    optional :platform, type: String, desc: 'User platform'
    optional :source, type: String, desc: 'Source of signup'
    optional :storefront_id, type: String, desc: 'Storefront ID'
  end
  post :waitlist do
    existing_user = RegisteredAccount.exists?(email: params[:email])

    unless existing_user
      if @storefront.nil? || @storefront.default_storefront?
        utm_cookie = if cookies[:utm]
                       JSON.parse(cookies[:utm], symbolize_names: true)
                     else
                       {}
                     end

        waitlist = ZipcodeWaitlist.find_or_create_by(zipcode: params[:zip_code],
                                                     email: params[:email],
                                                     apn_token: params[:one_signal_id],
                                                     platform: params[:platform],
                                                     source: params[:source],
                                                     utm_source: utm_cookie[:utm_source],
                                                     utm_campaign: utm_cookie[:utm_campaign],
                                                     utm_medium: utm_cookie[:utm_medium],
                                                     utm_term: utm_cookie[:utm_term],
                                                     utm_content: utm_cookie[:utm_content],
                                                     doorkeeper_application: doorkeeper_application)
        waitlist.save
      end

      @user&.update(email_subscribed: true)

      Segments::SegmentService.from(@storefront).identify_email_capture(params[:email], @user)
      Segments::SegmentService.from(@storefront).track_email_capture(params[:email], @user)
    end

    present :success, true
    present :account_exists, existing_user
  end
end
