# == Schema Information
#
# Table name: three_jms_credentials
#
#  id                :integer          not null, primary key
#  supplier_id       :integer
#  api_url           :string           not null
#  api_key           :string           not null
#  webhook_signature :string           not null
#
# Indexes
#
#  index_three_jms_credentials_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#
class Supplier::ThreeJMSCredential < ActiveRecord::Base
  self.table_name = 'three_jms_credentials'

  belongs_to :supplier, optional: false
  validates :api_url, :api_key, :webhook_signature, presence: true
end
