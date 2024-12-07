class ConsumerAPIV2::Entities::TextBanner < Grape::Entity
  expose :display_name, as: :name
  expose :internal_name
  expose :position
  expose :action_url
  expose :text_content
  expose :click_tracking_url
  expose :impression_tracking_url
  expose :background_color

  private

  def action_url
    return if object.target.blank?
    return object.target if options[:no_url_base].present?

    DeepLink.add_url_base(object.target)
  end

  def text_content
    object.text_content if object.content_type == :text
  end

  # TODO: Wire up tracking solution and make URL generator service.
  def click_tracking_url
    "https://track.minibardelivery.com/track?event_type=click&name=#{object.internal_name.parameterize}"
  end

  def impression_tracking_url
    "https://track.minibardelivery.com/track?event_type=impression&name=#{object.internal_name.parameterize}"
  end
end
