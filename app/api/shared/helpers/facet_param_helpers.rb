module Shared::Helpers::FacetParamHelpers
  def load_facets
    if params[:facet_list].blank?
      promo = PromotionWebFilter.find_by(match_tag: params[:tag]) if params[:base] == 'tag'
      promo = PromotionWebFilter.find_by(match_product_type: params[:hierarchy_category]&.first) if params[:base] == 'hierarchy_category'
      promo = PromotionWebFilter.find_by(match_search: 'brands') if params[:base] == 'brand'
      promo = PromotionWebFilter.find_by(internal_name: 'Web_PLP_Default_Filter') if promo.blank?
      params[:facet_list] = promo.promotion_filters.map(&:filter) if promo.present?
    end
  end
end
