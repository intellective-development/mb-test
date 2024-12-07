class Admin::Config::TopBannerMessagesController < Admin::Config::BaseController
  def index
    @message = TopBannerMessage.find_or_initialize_by(id: 1)
    @popup = TopBannerMessage.find_or_initialize_by(id: 2)
    @ondemand_email = TopBannerMessage.find_or_initialize_by(id: 3)
    @shipping_email = TopBannerMessage.find_or_initialize_by(id: 4)
    @pickup_email = TopBannerMessage.find_or_initialize_by(id: 5)
    @confirmation_email_bottom_one = TopBannerMessage.find_or_initialize_by(id: 6)
    @confirmation_email_bottom_two = TopBannerMessage.find_or_initialize_by(id: 7)
  end

  def edit
    @message = TopBannerMessage.find_or_initialize_by(id: params[:id])
    @skip_empty_p_tag_in_tinymce = true if @message.confirmation_email_bottom_banner?
  end

  def update
    @message = TopBannerMessage.find_or_initialize_by(id: params[:id])
    @message.update banner_message_params
    redirect_to action: :edit
  end

  private

  def banner_message_params
    params.require(:message).permit(:id, :text, :disabled, :color, :url, :permalinks_filters)
  end
end
