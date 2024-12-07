# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren

# == Schema Information
#
# Table name: ship_station_credentials
#
#  id                    :bigint(8)        not null, primary key
#  supplier_id           :integer          not null
#  api_key_ciphertext    :string
#  api_secret_ciphertext :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_ship_station_credentials_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#
class Supplier::ShipStationCredential < ApplicationRecord
  self.table_name = 'ship_station_credentials'
  belongs_to :supplier

  encrypts :api_key, :api_secret

  validates :supplier, :api_key, :api_secret, presence: true
end
# rubocop:enable Style/ClassAndModuleChildren
