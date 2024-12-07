class UpdateProductSizeGroupingImageJob < ActiveJob::Base
  queue_as :internal

  def perform(psg, image_url)
    psg.set_image(image_url)
  end
end
