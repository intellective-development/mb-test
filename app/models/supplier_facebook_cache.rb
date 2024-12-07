# == Schema Information
#
# Table name: supplier_facebook_caches
#
#  id                  :integer          not null, primary key
#  supplier_id         :integer
#  delivery_zone_cache :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  delivery_zone_id    :integer
#
# Indexes
#
#  index_supplier_facebook_caches_on_supplier_id  (supplier_id)
#

class SupplierFacebookCache < ActiveRecord::Base
  belongs_to :supplier
end
