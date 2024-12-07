class GiftDetailCreationService
  include SentryNotifiable

  attr_reader :user, :gift_detail_params

  def initialize(user, _options = {})
    @user = user
  end

  def create(params)
    @gift_detail_params = permitted_params(params)

    gift_details = user ? user.gift_details.new(gift_detail_params) : GiftDetail.new(gift_detail_params)

    gift_details.save!
    gift_details
  rescue StandardError => e
    notify_sentry_and_log(e)
    false
  end

  private

  def permitted_params(params)
    params.permit(:recipient_name, :recipient_phone, :recipient_email, :message)
  end
end
