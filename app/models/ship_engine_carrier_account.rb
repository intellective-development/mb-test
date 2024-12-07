# == Schema Information
#
# Table name: ship_engine_carrier_accounts
#
#  id          :integer          not null, primary key
#  uuid        :string(40)       not null
#  carrier     :string(40)       not null
#  supplier_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  address     :hstore
#
# Indexes
#
#  index_ship_engine_carrier_accounts_on_supplier_id              (supplier_id)
#  index_ship_engine_carrier_accounts_on_supplier_id_and_carrier  (supplier_id,carrier) UNIQUE
#  index_ship_engine_carrier_accounts_on_supplier_id_and_uuid     (supplier_id,uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#
class ShipEngineCarrierAccount < ActiveRecord::Base
  belongs_to :supplier, optional: false

  validates :uuid, :carrier, presence: true

  validates :carrier, uniqueness: { scope: :supplier_id }
  validates :uuid, uniqueness: { scope: :supplier_id }

  validates :carrier, inclusion: { in: ShipEngineAdapter::SUPPORTED_CARRIERS }

  before_destroy :prevent_deletion_if_account_undestroyable, prepend: true
  after_create :add_self_to_delegating_suppliers
  after_commit :remove_self_from_delegating_suppliers, on: :destroy

  def carrier=(value)
    super(value&.downcase)
  end

  def address=(value)
    raise ArgumentError.new, "Address should contain 'address1', 'city', 'state_name', 'zip_code' and 'phone' keys" unless %w[address1 city state_name zip_code phone].all? { |key| value.stringify_keys.key?(key) }

    super(value)
  end

  private

  def prevent_deletion_if_account_undestroyable
    return if destroyable?

    errors.add(:base, 'This account from delegating supplier cannot be deleted if the same account from delegate supplier still exists')
    throw :abort
  end

  def add_self_to_delegating_suppliers
    return if supplier.delegating?

    supplier.delegate_suppliers.each do |delegate_supplier|
      accs = delegate_supplier.ship_engine_carrier_accounts

      next if accs.find_by(carrier: carrier, uuid: uuid).present?

      dup_self = dup
      accs << dup_self
    end
  end

  def remove_self_from_delegating_suppliers
    return if supplier.delegating?

    supplier.delegate_suppliers.each do |delegate_supplier|
      acc = delegate_supplier.ship_engine_carrier_accounts.find_by(carrier: carrier, uuid: uuid)

      next if acc.nil?

      acc.destroy
    end
  end

  def destroyable?
    return true unless supplier.delegating?

    supplier.delegate.ship_engine_carrier_accounts.find_by(carrier: carrier, uuid: uuid).nil?
  end
end
