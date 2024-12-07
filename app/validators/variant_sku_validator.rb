class VariantSKUValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    existing_variant = Variant.self_active.where(sku: value, supplier_id: record.supplier_id).where.not(id: record.id).any?
    record.errors.add(attribute, "#{value} already exists for Supplier #{record.supplier_id}") if existing_variant
  end
end
