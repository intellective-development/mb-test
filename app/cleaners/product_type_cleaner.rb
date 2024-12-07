class ProductTypeCleaner
  def self.parse(string, root_category)
    root_product_type = ProductType.roots.find_by(name: root_category)
    if root_product_type
      matches = root_product_type.descendants.select { |pt| string.to_s.downcase.include?(pt.name.downcase) }
      if matches.size == 1
        matches.first.name
      else
        Rails.logger.info("#{descendants.size} results for #{string} - Cannot reliably infer product type")
      end
    else
      Rails.logger.info("Cannot find root product type for #{root_category}")
    end
  end
end
