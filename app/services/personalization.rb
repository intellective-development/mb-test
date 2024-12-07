class Personalization
  def self.get_root_categories(_supplier, product_type_ids)
    select_supplier_products(ProductType.roots.active.includes(:image).order(:position), product_type_ids)
  end

  def self.get_types(_supplier, category, product_type_ids)
    select_supplier_products(category.children.order(:position), product_type_ids)
  end

  def self.get_plp_promotions(supplier_ids, options, is_web = false, suppress_promotions = false)
    if suppress_promotions # Temporary workaround for iPad while we figure out formatting
      []
    else
      is_web ? select_promotions(PromotionWebPLPModule, supplier_ids, options) : select_promotions(PromotioniOSPLPModule, supplier_ids, options)
    end
  end

  def self.select_promotions(model, supplier_ids, options = {})
    promotions = model.active.at(Time.zone.now).for_supplier(supplier_ids).select { |p| p.eligible?(options || {}) }
    promotions.uniq
  end

  def self.select_supplier_products(collection, product_type_ids)
    collection.select { |c| c.image.present? && (product_type_ids.include?(c.id) || !(c.descendants.pluck(:id) & product_type_ids).empty?) }
  end
end
