# == Schema Information
#
# Table name: brand_distributor_associations
#
#  id             :integer          not null, primary key
#  brand_id       :integer
#  distributor_id :integer
#  created_at     :datetime
#  updated_at     :datetime
#  state_id       :integer
#
# Indexes
#
#  index_brand_distributor_associations_on_state_id  (state_id)
#
# Foreign Keys
#
#  fk_rails_...  (state_id => states.id)
#

class BrandDistributorAssociation < ActiveRecord::Base
  belongs_to :brand
  belongs_to :distributor
  belongs_to :state
end
