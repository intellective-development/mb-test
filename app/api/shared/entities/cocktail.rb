class Shared::Entities::Cocktail < Grape::Entity
  expose :title
  expose :tag
  expose :thumbnail_url
  expose :img_url
  expose :ingredients
  expose :copy
  expose :product_name
  expose :product_img_url
  expose :product_url

  private

  def title
    I18n.t("cocktails.#{object.permalink}.title")
  end

  def tag
    I18n.t("cocktails.#{object.permalink}.tag")
  end

  def thumbnail_url
    ActionController::Base.helpers.asset_path("promos/pernod-ricard-winter/#{object.permalink}_no_people.jpg")
  end

  def img_url
    ActionController::Base.helpers.asset_path("promos/pernod-ricard-winter/#{object.permalink}_people.jpg")
  end

  def ingredients
    I18n.t("cocktails.#{object.permalink}.ingredients").map do |string|
      I18n.interpolate(string, name: product_name, url: product_url)
    end
  end

  def copy
    I18n.t("cocktails.#{object.permalink}.copy")
  end

  def product_name
    I18n.t("cocktails.#{object.permalink}.product_name")
  end

  def product_img_url
    object.featured_image(:product)
  end

  def product_url
    DeepLink.product_grouping(object)
  end
end
