# == Schema Information
#
# Table name: supplier_package_size_presets
#
#  id           :integer          not null, primary key
#  dimensions   :hstore
#  weight       :hstore
#  bottle_count :integer
#  supplier_id  :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  idx_supplier_pkg_size_presets_on_bottle_count_and_supplier_id  (bottle_count,supplier_id) UNIQUE
#  index_supplier_package_size_presets_on_supplier_id             (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#
class Supplier::PackageSizePreset < ApplicationRecord
  belongs_to :supplier, optional: false

  validates :dimensions, :weight, presence: true
  validates :bottle_count, uniqueness: { scope: :supplier_id, message: 'already exists for this supplier' }
  validate :dimensions_cannot_contain_invalid_keys
  validate :weight_cannot_contain_invalid_keys
  validate :supplier_cannot_be_delegating

  private

  def dimensions_cannot_contain_invalid_keys
    errors.add(:dimensions, "should contain 'length', 'width' and 'height' keys") unless %w[length width height].all? { |key| Hash(dimensions).key?(key) }
  end

  def weight_cannot_contain_invalid_keys
    errors.add(:weight, "should contain 'value' and 'unit' keys") unless %w[value unit].all? { |key| Hash(weight).key?(key) }
  end

  def supplier_cannot_be_delegating
    return if supplier.nil?

    errors.add(:supplier, 'cannot be delegating') if supplier.delegating?
  end
end
