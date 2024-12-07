# == Schema Information
#
# Table name: prototype_properties
#
#  id           :integer          not null, primary key
#  prototype_id :integer          not null
#  property_id  :integer          not null
#

class PrototypeProperty < ActiveRecord::Base
  belongs_to :prototype
  belongs_to :property

  validates :prototype_id, presence: true
  validates :property_id, presence: true
end
