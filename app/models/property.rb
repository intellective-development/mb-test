# == Schema Information
#
# Table name: properties
#
#  id              :integer          not null, primary key
#  identifing_name :string(255)      not null
#  display_name    :string(255)
#  active          :boolean          default(TRUE), not null
#

class Property < ActiveRecord::Base
  has_many :prototype_properties
  has_many :prototypes, through: :prototype_properties

  has_many :product_properties

  scope :visible, -> { where(active: true) }

  validates :identifing_name,    presence: true, length: { maximum: 250 }
  validates :display_name,       presence: true, length: { maximum: 165 }
  # active is default true at the DB level

  def full_name
    "#{display_name}: (#{identifing_name})"
  end

  # paginated results from the admin Property grid
  #
  # @param [Optional params]
  # @return [ Array[Property] ]
  def self.admin_grid(params = {})
    grid = Property.all
    grid = grid.where('properties.display_name LIKE ?', "#{params[:display_name]}%") if params[:display_name].present?
    grid = grid.where('properties.identifing_name LIKE ?', "#{params[:identifing_name]}%") if params[:identifing_name].present?
    grid
  end

  def self.find_by_name(name)
    find_by(identifing_name: name)
  end

  # 'True' if active 'False' otherwise in plain english
  #
  # @param [none]
  # @return [String] 'True' or 'False'
  def display_active
    active? ? 'Yes' : 'No'
  end
end
