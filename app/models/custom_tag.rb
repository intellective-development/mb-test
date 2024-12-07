# == Schema Information
#
# Table name: custom_tags
#
#  id          :integer          not null, primary key
#  name        :string
#  color       :string
#  description :string
#  supplier_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_custom_tags_on_supplier_id  (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (supplier_id => suppliers.id)
#
class CustomTag < ActiveRecord::Base
  belongs_to :supplier
  has_many :custom_tag_shipments, dependent: :destroy
  has_many :shipments, through: :custom_tag_shipments

  validates :name, uniqueness: { scope: [:supplier_id] }
end
