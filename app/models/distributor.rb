# == Schema Information
#
# Table name: distributors
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime
#  updated_at :datetime
#

class Distributor < ActiveRecord::Base
  has_many :brand_distributor_associations, dependent: :destroy
  has_many :brands, through: :brand_distributor_associations

  #-----------------------------------
  # Class methods
  #-----------------------------------
  def self.name_filter(params = {})
    name = params[:name].presence
    name ? where('lower(distributors.name) LIKE lower(?)', "#{name}%") : all
  end
end
