# == Schema Information
#
# Table name: tax_rates
#
#  id              :integer          not null, primary key
#  percentage      :decimal(8, 4)    default(0.0), not null
#  state_id        :integer
#  country_id      :integer
#  start_date      :date             not null
#  end_date        :date
#  active          :boolean          default(TRUE), not null
#  zipcode         :string(255)
#  tax_category_id :integer
#  default         :boolean          default(FALSE), not null
#
# Indexes
#
#  index_tax_rates_on_state_id         (state_id)
#  index_tax_rates_on_tax_category_id  (tax_category_id)
#

class TaxRate < ActiveRecord::Base
  has_paper_trail

  belongs_to :state
  belongs_to :country
  belongs_to :tax_category

  validates :percentage, numericality: true, presence: true
  validates :start_date, presence: true

  after_create :expire_active_tax_rates
  after_save :expire_cache
  before_save :become_the_default, if: :default_changed?

  delegate :name, to: :state, prefix: true, allow_nil: true

  #-----------------------------------
  # Scopes
  #-----------------------------------
  scope :shipping, -> { joins(:tax_category).merge(TaxCategory.shipping) }
  scope :by_start_date, -> { order('start_date DESC') }
  scope :at, ->(time = Time.current) { active_at(time.to_date) }
  scope :active, -> { where(['tax_rates.active = ?', true]) }
  scope :active_at, ->(date = Time.zone.today) { where(['tax_rates.start_date <= ? AND (end_date > ? OR end_date IS NULL)', date.to_s(:db), date.to_s(:db)]) }
  scope :for_state, ->(id) { where(state_id: id) }
  scope :for_zipcode, ->(zipcode) { where(zipcode: zipcode) }
  scope :for_category, ->(id) { where(tax_category_id: id) }
  scope :for_state_and_zipcode, ->(state_id, zipcode) { where('state_id = ? OR zipcode = ?', state_id, zipcode) }

  #-----------------------------------
  # Class methods
  #-----------------------------------
  def self.admin_grid(params = {})
    grid = TaxRate.order(:state_id, :zipcode)
    grid = grid.joins('LEFT JOIN states ON tax_rates.state_id = states.id').includes(:tax_category)
    grid = grid.where('lower(states.name) LIKE :search OR lower(states.abbreviation) LIKE :search OR tax_rates.zipcode LIKE :search', { search: "%#{params[:zipcode].downcase}%" }) if params[:zipcode].present?
    grid
  end

  def self.active_at_ids(_date = Time.zone.today)
    active_at.pluck(:id)
  end

  # TODO: JM: I want to find a way to cache this in memory, but the time element breaks it.
  # I'm not sure the time is actually relavent unless there is a new rate or change of rate
  # so perhaps the key could be "TaxRate-zip-99999-state-NY-category-id"
  # then invalidate the cache or refresh it when we have a new rate?

  # Gives you the tax rate for the give state_id and the time.
  # Tax rates can change from year to year so Time is a factor
  def self.lookup(zipcode, state_id, category_id, time = Time.current)
    base_scope = for_category(category_id).at(time).active.by_start_date
    base_scope.find_by(zipcode: zipcode) || base_scope.find_by(state_id: state_id, zipcode: '') || find_by(default: true) || find_by(percentage: 8.875)
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------
  def become_the_default
    TaxRate.where(default: true).update_all(default: false) if default?
  end

  def inactivate!
    update(active: false)
  end

  def expire!
    update(end_date: Date.today, active: false)
  end

  def expire_active_tax_rates
    is_active = active || start_date <= Date.today

    active_tax_rates = TaxRate.where.not(id: id)
                              .where(active: true, state_id: state_id, zipcode: zipcode, tax_category_id: tax_category_id)
                              .where('end_date > ?', start_date)

    active_tax_rates.each do |tax_rate|
      tax_rate.end_date = start_date
      tax_rate.active = false if is_active
      tax_rate.save!
    end
  end

  private

  def expire_cache
    Rails.cache.delete("TaxRate-#{I18n.t(:company)}-active_at_ids-#{Date.yesterday}")
    Rails.cache.delete("TaxRate-#{I18n.t(:company)}-active_at_ids-#{Date.today}")
    Rails.cache.delete("TaxRate-#{I18n.t(:company)}-active_at_ids-#{Date.tomorrow}")
  end
end
