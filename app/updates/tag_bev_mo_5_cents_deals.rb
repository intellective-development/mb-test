module TagBevMo5CentsDeals
  def self.call
    Variant.where(supplier_id: store_ids, two_for_one: 0.05).each do |variant|
      product_size_grouping = variant.product.product_size_grouping
      unless product_size_grouping.tag_list.include?('5centdeal')
        product_size_grouping.tag_list.add('5centdeal')
        product_size_grouping.save
      end
    end
  end

  def self.store_ids
    Supplier.where('name iLIKE ?', '%BevMo%').pluck(:id)
  end

  private_class_method :store_ids
end
