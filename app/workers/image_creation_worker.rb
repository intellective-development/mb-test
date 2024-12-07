class ImageCreationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 2,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(model, model_id, image_url)
    return true if image_url.nil?

    product = model.constantize.find_by_id(model_id)
    raise 'ImageCreationWorker: Model not found' if product.nil?

    begin
      product.images.create!(photo_from_link: image_url)
    rescue StandardError
      nil
    end
  end
end
