class BrandAPIV1::Entities::User < Grape::Entity
  expose :id
  expose :first_name
  expose :last_name
  expose :email
  expose :product_size_grouping_ids
  expose :brand_name

  private

  def brand_name
    object&.brand&.name
  end

  def product_size_grouping_ids
    object&.brand&.active_self_and_descendents_product_groupings&.pluck(:id)
  end
end
