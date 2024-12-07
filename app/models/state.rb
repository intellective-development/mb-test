# == Schema Information
#
# Table name: states
#
#  id                 :integer          not null, primary key
#  name               :string(255)      not null
#  abbreviation       :string(5)        not null
#  described_as       :string(255)
#  country_id         :integer          not null
#  slug               :string
#  statewide_shipping :boolean
#

# States are "states, territories and provinces" of a country. This table is seeded from
#   the db/seeds.rb file.  The seed data is supplied by db/seed/international_states/*.yml files.
#

class State < ActiveRecord::Base
  extend FriendlyId

  belongs_to :country
  has_many :addresses
  has_many :tax_rates
  has_many :regions
  has_many :cities, through: :regions

  friendly_id :name, use: [:slugged]

  validates :name,         presence: true, length: { maximum: 150 }
  validates :abbreviation, presence: true, length: { maximum: 12 }
  validates :country,      presence: true

  scope :by_abbreviation, -> { order(abbreviation: :asc) }
  scope :us_states, -> { where(country_id: 1, described_as: 'State') }

  #------------------------------------------------------------
  # Class methods
  #------------------------------------------------------------
  # method to get all the states for a form
  # [['NY New York', 32], ['CA California', 3] ... ]
  #
  # @param [none]
  # @return [ Array[Array] ]
  def self.form_selector
    order('country_id ASC, abbreviation ASC').collect { |state| [state.abbrev_and_name, state.id] }
  end

  # filter all the states for a form for a given country_id
  #
  # @param [Integer] country_id
  # @return [ Arel ]
  def self.all_with_country_id(c_id)
    where(country_id: c_id)
  end

  def self.lookup_state_id(state_name)
    clean_name = String(state_name).strip.upcase
    Rails.cache.fetch("State-state_name-#{clean_name}") do
      where('abbreviation = :clean_name OR name ilike :clean_name', clean_name: clean_name).limit(1).pluck(:id).first
    end
  end

  #------------------------------------------------------------
  # Instance methods
  #------------------------------------------------------------
  # the abbreviation and name of the state separated by '-' and optionally appended by characters
  #
  # @param [none]
  # @return [ String ]
  def abbreviation_name(append_name = '')
    ([abbreviation, name].join(' - ') + " #{append_name}").strip
  end

  # the abbreviation and name of the state separated by '-'
  #
  # @param [none]
  # @return [ String ]
  def abbrev_and_name
    abbreviation_name
  end

  def update_deliverable_cities(visible_cities)
    visible_city_ids = visible_cities.select(&:present?)
    hidden_cities = cities.where(visible: false, id: visible_city_ids)
    to_hide_cities = cities.where(visible: true).where.not(id: visible_city_ids)
    hidden_cities.update_all(visible: true)
    to_hide_cities.update_all(visible: false)

    true
  rescue StandardError
    false
  end

  def deliverable_cities
    cities.visible.sorted
  end

  def deliverable_city_ids
    deliverable_cities.pluck('cities.id')
  end
end
