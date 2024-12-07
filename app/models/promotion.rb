# == Schema Information
#
# Table name: promotions
#
#  id                           :integer          not null, primary key
#  internal_name                :string(255)      not null
#  display_name                 :string(255)      not null
#  starts_at                    :datetime
#  ends_at                      :datetime
#  active                       :boolean          default(TRUE), not null
#  type                         :string(255)      not null
#  promotable_type              :string(255)      not null
#  created_at                   :datetime
#  updated_at                   :datetime
#  target                       :text
#  position                     :integer          default(0)
#  image_file_name              :string(255)
#  image_content_type           :string(255)
#  image_file_size              :integer
#  image_updated_at             :datetime
#  image_width                  :integer
#  image_height                 :integer
#  match_tag                    :string(255)
#  match_product_type           :string(255)
#  match_search                 :string(255)
#  match_category               :string(255)
#  background_color             :string(255)
#  priority                     :integer
#  content_placement_id         :integer
#  exclude_logged_in_user       :boolean          default(FALSE)
#  secondary_image_file_name    :string(255)
#  secondary_image_content_type :string(255)
#  secondary_image_file_size    :integer
#  secondary_image_updated_at   :datetime
#  exclude_logged_out_user      :boolean
#  text_content                 :string(255)
#  match_page_type              :string(255)
#
# Indexes
#
#  index_promotions_on_content_placement_id  (content_placement_id)
#  index_promotions_on_id_and_type           (id,type)
#

class Promotion < ActiveRecord::Base
  validates :internal_name, presence: true
  validates :display_name,  presence: true
  validates :starts_at,     presence: true
  validates :ends_at, presence: true

  auto_strip_attributes :internal_name, :display_name, :target, squish: true

  has_many :promotion_items, autosave: true, dependent: :destroy
  has_and_belongs_to_many :promotion_filters

  has_one :content_placement, as: :default_promotion

  belongs_to :content_placement

  scope :at, ->(now) { where('promotions.starts_at <= ?', now).where('promotions.ends_at >= ?', now) }
  scope :active,   -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # TOOD: Do we want to also incorporate a DISTINCT into this scope to prevent duplicates?
  scope :for_supplier, lambda { |supplier_ids|
    # We expect an array of supplier id's but want to handle the case where a single ID
    # is provided. Ultimately we may wish to remove this.
    supplier_ids = String(supplier_ids).split(',') unless supplier_ids.is_a?(Array)

    joins('LEFT JOIN promotion_items on promotion_items.promotion_id = promotions.id')
      .where('(promotion_items.item_type = :item_type AND promotion_items.item_id = ANY(ARRAY[:item_id]::INT[])) OR promotion_items.id IS NULL', item_type: 'Supplier', item_id: supplier_ids)
  }

  PROMOTION_TYPES = %w[PromotionMobileBanner PromotionWebBanner PromotioniOSPLPModule PromotionWebPLPModule PromotionWebFilter].freeze

  has_attached_file :image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'promotions/:id/:style/:basename.:extension')
  validates_attachment :image, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates_attachment_size :image, less_than: 1.megabytes

  has_attached_file :secondary_image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'promotions/:id/:style/mobile/:basename.:extension')
  validates_attachment :secondary_image, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates_attachment_size :secondary_image, less_than: 1.megabytes

  before_save :extract_dimensions

  attr_accessor :p_type, :promotable_ids

  def pending?
    Time.zone.now < starts_at
  end

  def expired?
    Time.zone.now > ends_at
  end

  def display_start_time(format = :us_date)
    starts_at ? I18n.localize(starts_at, format: format) : 'N/A'
  end

  def display_expires_time(format = :us_date)
    ends_at ? I18n.localize(ends_at, format: format) : 'N/A'
  end

  def promotable_ids
    promotion_items.pluck(:item_id)
  end

  def promotable_ids=(ids)
    ids = ids.select(&:present?).map(&:to_i)

    if promotable_type.present? && !ids.empty?
      item_type = promotable_type.camelize

      self.promotion_items = [] if promotion_items.any? { |si| si.item_type != promotable_type }

      old_persisted_ids   = promotion_items.pluck(:item_id)
      newly_adding_ids    = Set.new(ids).subtract(old_persisted_ids)
      newly_deleting_ids  = Set.new(old_persisted_ids).subtract(ids)

      ditems = promotion_items.select { |si| newly_deleting_ids.include?(si.item_id) }.each(&:destroy)

      newly_adding_ids.each do |item_id|
        promotion_items.build(item_type: item_type, item_id: item_id) if item_id.present?
      end
    end
  end

  def impression_tracking_id
    "#{internal_name}__impression"
  end

  def click_tracking_id
    "#{internal_name}__click"
  end

  # These three are primarily intended for web hero
  def content_type
    if image.present?
      :image
    elsif text_content.present?
      :text
    end
  end

  def primary_content
    case content_type
    when :image then image&.url
    when :text then text_content
    end
  end

  def secondary_content
    secondary_image.url if content_type == :image && secondary_image.present?
  end

  def matchers_valid?(options = {})
    matches_tag = check_matcher(match_tag, options[:tag])
    matches_search = check_matcher(match_search, options[:search])
    matches_product_type = check_matcher(match_product_type, options[:type])
    matches_page_type = check_matcher(match_page_type, options[:page_type])

    matches_tag || matches_search || matches_product_type || matches_page_type
  end

  def image_width
    self[:image_width] || 0
  end

  def image_height
    self[:image_height] || 0
  end

  private

  def check_matcher(matcher, option_val)
    matcher.present? && matcher.split(',').include?(String(option_val).downcase)
  end

  def extract_dimensions
    tempfile = image.queued_for_write[:original]
    unless tempfile.nil?
      geometry = Paperclip::Geometry.from_file(tempfile)
      self.image_width  = geometry.width.to_i || 0
      self.image_height = geometry.height.to_i || 0
    end
  end
end
