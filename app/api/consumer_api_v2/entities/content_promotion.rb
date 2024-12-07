class ConsumerAPIV2::Entities::ContentPromotion < Grape::Entity
  expose :content_type, as: :type
  expose :primary_content, as: :content
  expose :secondary_content

  # TODO: Convert the target url into universal deeplink format.
  # TODO: We may want to think about a cleaner, less case-by-case, way to do
  #       this once we have support in iOS and start using them everywhere.
  expose :target
  expose :impression_tracking_id
  expose :click_tracking_id
  expose :placement do |_p|
    options[:placement_name].to_s
  end
  expose :metadata do
    # This is for Placement specific metadata (e.g. background colors, titles)
    expose :display_name, as: :alt
    expose :image_height, as: :height
    expose :image_width, as: :width
    expose :background_color
  end
end
