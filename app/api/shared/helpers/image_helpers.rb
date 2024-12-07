module Shared::Helpers::ImageHelpers
  def image_with_fallback(image, fallback)
    image.blank? || image.to_s =~ /processing/ ? fallback : image
  end
end
