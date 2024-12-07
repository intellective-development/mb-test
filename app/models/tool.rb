# == Schema Information
#
# Table name: tools
#
#  id          :integer          not null, primary key
#  name        :text
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Tool < ActiveRecord::Base
  has_many :cocktail_tools
  has_many :cocktails, through: :cocktail_tools
  has_one :icon, class_name: 'Asset', as: :owner, dependent: :destroy

  def self.admin_grid(params = {}, _active_state = nil)
    name_filter(params[:name])
  end

  def self.name_filter(name)
    name.present? ? where('lower(tools.name) LIKE lower(?)', "%#{name}%") : all
  end
end
