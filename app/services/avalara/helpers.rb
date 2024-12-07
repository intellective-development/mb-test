module Avalara
  class Helpers
    def self.get_variant_tax_code(variant)
      return 'NT' if variant.tax_exempt?

      product = variant.product
      return product.tax_code if product.tax_code.present?

      product.product_type&.get_tax_code
    end

    def self.get_avalara_volume_unit(unit)
      return nil if unit.nil?

      unit = unit.upcase

      return 'pint' if unit == 'PINT'
      return 'Millilitre' if unit == 'ML'
      return 'ounce (fluid imperial)' if unit == 'OZ'
      return 'gallon (US fluid)' if unit.match(/GAL/)
      return 'Litre' if unit == 'L'

      nil
    end

    def self.get_variant_properties(variant)
      product = variant&.product
      container_type = variant&.container_type

      return [] if container_type.nil? || !%w[can bottle].include?(container_type.downcase)

      container_type = case container_type.downcase
                       when 'can'
                         'Metal'
                       when 'bottle'
                         'Glass'
                       end

      pack_size = product&.container_count || 1

      properties = []
      properties << { name: 'BeverageContainerMaterial', value: container_type }
      properties << { name: 'PackSize', value: pack_size, unit: 'Count' }

      volume_value = product&.volume_value
      volume_unit = Avalara::Helpers.get_avalara_volume_unit(product&.volume_unit)

      properties << { name: 'NetVolume', value: volume_value.to_f, unit: volume_unit } if volume_value.present? && volume_unit.present?

      properties
    end

    def self.get_taxable_address(shipment, fallback_address = nil)
      address = shipment.pickup? ? shipment.supplier_address : shipment.address
      address ||= fallback_address
      address ||= shipment.supplier_address

      address
    end
  end
end
