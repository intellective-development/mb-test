class ProductImageUrlService
  def self.get_url(product_image_id, product_image_file_name, fallback_image_id, size = :product)
    if product_image_id && product_image_file_name
      get_product_image_url(product_image_id, product_image_file_name, size)
    elsif fallback_image_id
      "#{paperclip_url_base}/product_types/#{fallback_image_id}/#{size}.jpg"
    else
      ActionController::Base.helpers.image_url("/product_defaults/#{size}.jpg")
    end
  end

  def self.get_product_image_url(product_image_id, product_image_file_name, size = :product)
    # this takes about 1/3 of the time when generating entity
    # If we ever do make the image filepaths more manageable, it would be nice
    # to refactor this out.
    product_image_file_name_jpg = "#{File.basename(product_image_file_name, '.*')}.jpg"
    "#{paperclip_url_base}/products/#{product_image_id}/#{size}/#{product_image_file_name_jpg}"
  end

  def self.paperclip_url_base
    paperclip_options = Paperclip::Attachment.default_options
    if paperclip_options[:s3_host_alias]
      "#{paperclip_options[:s3_protocol]}://#{paperclip_options[:s3_host_alias]}"
    else
      paperclip_options[:fog_host].to_s
    end
  end
end
