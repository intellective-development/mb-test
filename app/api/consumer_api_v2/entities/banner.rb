class ConsumerAPIV2::Entities::Banner < Grape::Entity
  expose :display_name, as: :name
  expose :internal_name
  expose :position
  expose :action_url
  expose :image_url
  expose :image_width
  expose :image_height
  expose :secondary_image_url
  expose :click_tracking_url
  expose :impression_tracking_url

  private

  def action_url
    return if object.target.blank?
    return object.target if options[:no_url_base].present?

    DeepLink.add_url_base(object.target)
  end

  def image_url
    object.image.url
  end

  # TODO: Consider consolidating pixel density calculations
  def image_width
    object.image_width / 3
  end

  def image_height
    object.image_height / 3
  end

  def secondary_image_url
    object.secondary_image ? object.secondary_image.url : image_url
  end

  # TODO: Wire up tracking solution and make URL generator service.
  def click_tracking_url
    "https://track.minibardelivery.com/track?event_type=click&name=#{object.internal_name.parameterize}"
  end

  def impression_tracking_url
    "https://track.minibardelivery.com/track?event_type=impression&name=#{object.internal_name.parameterize}"
  end
end
