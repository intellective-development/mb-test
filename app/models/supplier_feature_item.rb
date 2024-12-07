# == Schema Information
#
# Table name: supplier_feature_items
#
#  id              :integer          not null, primary key
#  supplier_id     :integer          not null
#  feature_item_id :integer          not null
#  created_at      :datetime
#  updated_at      :datetime
#

class SupplierFeatureItem < ActiveRecord::Base
  belongs_to :feature_item
  belongs_to :supplier
end
