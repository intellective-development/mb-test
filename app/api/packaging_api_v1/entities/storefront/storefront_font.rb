class PackagingAPIV1::Entities::Storefront::StorefrontFont < Grape::Entity
  expose :name
  expose :font_family
  expose :font_type
  expose :file_url

  private

  def name
    object.name.parameterize
  end

  def font_family
    object.name
  end

  def file_url
    object.font_file&.url
  end
end
