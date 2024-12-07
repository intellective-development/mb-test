# == Schema Information
#
# Table name: storefronts
#
#  id                                      :integer          not null, primary key
#  business_id                             :integer          not null
#  name                                    :string
#  pim_name                                :string
#  ecp_provider                            :integer
#  status                                  :integer          default("inactive"), not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  home_url                                :string
#  google_tag_id                           :string
#  enable_side_referral                    :boolean
#  enable_live_chat                        :boolean
#  enable_footer                           :boolean
#  enable_auto_refill                      :boolean
#  enable_substitution                     :boolean
#  logo_file_file_name                     :string
#  logo_file_content_type                  :string
#  logo_file_file_size                     :bigint(8)
#  logo_file_updated_at                    :datetime
#  mobile_logo_file_file_name              :string
#  mobile_logo_file_content_type           :string
#  mobile_logo_file_file_size              :bigint(8)
#  mobile_logo_file_updated_at             :datetime
#  fulfillment_types                       :string           is an Array
#  segment_tag_id                          :string
#  single_shipping_fee                     :decimal(5, 2)    not null
#  supplier_fee_mode                       :integer          not null
#  hostname                                :string
#  oauth_application_id                    :integer
#  enable_authenticated_checkout           :boolean
#  enable_in_stock_check                   :boolean          default(TRUE)
#  enable_supplier_order_mins              :boolean
#  email_capture_title                     :string
#  email_capture_subtitle                  :string
#  button_color                            :string(7)
#  footer_copy                             :text
#  email_capture_mode                      :integer          default("never"), not null
#  favicon_file_file_name                  :string
#  favicon_file_content_type               :string
#  favicon_file_file_size                  :bigint(8)
#  favicon_file_updated_at                 :datetime
#  success_content_mobile_screen_id        :integer
#  auth_provider                           :integer          default("devise_auth")
#  auth0_domain_ciphertext                 :text
#  auth0_client_id_ciphertext              :text
#  auth0_client_secret_ciphertext          :text
#  auth0_audience_ciphertext               :text
#  auth0_db_connection_ciphertext          :text
#  auth0_logo_file_file_name               :string
#  auth0_logo_file_content_type            :string
#  auth0_logo_file_file_size               :bigint(8)
#  auth0_logo_file_updated_at              :datetime
#  support_phone_number                    :string
#  support_email                           :string           default(""), not null
#  segment_write_key_ciphertext            :text
#  shipped_method_desc                     :string
#  on_demand_method_desc                   :string
#  enable_sms_opt_in                       :boolean          default(FALSE)
#  enable_email_opt_in                     :boolean          default(FALSE)
#  enable_back_order_placement             :boolean          default(FALSE)
#  enable_pre_sale_placement               :boolean          default(FALSE)
#  enable_sift_fraud                       :boolean          default(TRUE), not null
#  enable_multiple_coupons                 :boolean          default(FALSE), not null
#  enable_birthdate_collection             :boolean          default(FALSE), not null
#  enable_engravings                       :boolean          default(TRUE)
#  merchandise_fulfillment_desc            :string
#  enable_legal_age_collection             :boolean          default(FALSE)
#  age_verify_copy                         :string
#  back_order_method_desc                  :string
#  auth0_api_client_id_ciphertext          :text
#  auth0_api_client_secret_ciphertext      :text
#  enable_video_gift_message               :boolean          default(FALSE)
#  auth0_api_domain_ciphertext             :text
#  n_rsa_count                             :integer          default(1)
#  threejms_brand                          :string
#  enable_dynamic_shipping                 :boolean          default(FALSE)
#  apple_merchant_id                       :text
#  apple_merchant_name                     :string
#  tracking_page_hostname                  :string
#  enable_mikmak_feed                      :boolean          default(FALSE)
#  rsa_price_type                          :integer          default("lowest")
#  parent_storefront_id                    :integer
#  legal_text                              :text
#  inherits_tracking_page                  :boolean          default(FALSE)
#  enable_graphic_engraving                :boolean          default(FALSE)
#  uuid                                    :uuid
#  requires_payment_partner_authentication :boolean          default(FALSE)
#  ga_id                                   :string
#  iterable_api_key_ciphertext             :text
#  custom_checkout_css                     :text
#  enable_checkout_v3                      :boolean          default(TRUE)
#  enable_price_range_selection            :boolean
#  allow_price_range_fallback              :boolean
#  min_selection_price                     :decimal(8, 2)
#  max_selection_price                     :decimal(8, 2)
#  omit_comms                              :boolean          default(FALSE)
#  permalink                               :string(255)
#  default_sms_opt_in                      :boolean          default(FALSE)
#  default_email_opt_in                    :boolean          default(TRUE)
#  sms_legal_text                          :text
#  engraving_fee                           :decimal(5, 2)    default(50.0), not null
#  is_liquid                               :boolean          default(FALSE)
#  enable_zone_proximity_selection         :boolean          default(FALSE)
#  client_id                               :string
#  sdk_whitelisted_domains                 :jsonb            is an Array
#  shopify_domain                          :string
#  enable_oos_availability_check           :boolean          default(FALSE), not null
#  oos_amount_willing_to_cover             :decimal(8, 2)
#  shipping_fee_covered_by_rb              :boolean          default(FALSE)
#
# Indexes
#
#  index_storefronts_on_business_id                       (business_id)
#  index_storefronts_on_name                              (name) UNIQUE
#  index_storefronts_on_oauth_application_id              (oauth_application_id) UNIQUE
#  index_storefronts_on_parent_storefront_id              (parent_storefront_id)
#  index_storefronts_on_permalink                         (permalink) UNIQUE
#  index_storefronts_on_pim_name                          (pim_name) UNIQUE
#  index_storefronts_on_success_content_mobile_screen_id  (success_content_mobile_screen_id)
#  index_storefronts_on_uuid                              (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (business_id => businesses.id)
#  fk_rails_...  (oauth_application_id => oauth_applications.id)
#  fk_rails_...  (parent_storefront_id => storefronts.id)
#  fk_rails_...  (success_content_mobile_screen_id => content_mobile_screens.id)
#
class Storefront < ActiveRecord::Base
  extend FriendlyId
  include Iterable::Storefront::Serializers::StorefrontSerializer
  include Storefronts::HasTrackingPage
  include Storefronts::HasOosAvailabilityCheckAllowance

  friendly_id :permalink_candidates, use: %i[slugged finders history], slug_column: :permalink
  alias_attribute :slug, :permalink

  MINIBAR_ID = 1
  RESERVEBAR_ID = 2
  GET_STOCKED_ID = 3

  FULFILLMENT_TYPES = %w[pickup on_demand shipped scheduled_delivery].freeze

  enum ecp_provider: { sfcc: 0, shopify: 1, non_endemic: 2 }
  enum email_capture_mode: { never: 0, auth_only: 1, all_steps: 2 }, _prefix: true
  enum status: { inactive: 0, active: 1 }
  enum supplier_fee_mode: { all: 0, first: 1 }, _prefix: true
  enum auth_provider: { devise_auth: 0, auth0: 1 }
  enum rsa_price_type: { lowest: 0, highest: 1 }

  belongs_to :business
  belongs_to :oauth_application, class_name: 'Doorkeeper::Application'
  belongs_to :success_screen,
             class_name: 'Content::MobileScreen',
             foreign_key: :success_content_mobile_screen_id,
             optional: true
  belongs_to :parent_storefront, class_name: 'Storefront'

  has_many :storefront_links
  has_many :storefront_fonts

  has_one :cname_record
  has_one :webhook, class_name: 'StorefrontWebhook', dependent: :destroy

  has_many :orders
  has_many :registered_accounts
  has_many :digital_packing_slip_placements
  has_many :membership_plans, inverse_of: :storefront, dependent: nil
  has_many :memberships, inverse_of: :storefront, dependent: nil
  has_many :coupons
  has_many :membership_plans, inverse_of: :storefront, dependent: nil
  has_many :memberships, inverse_of: :storefront, dependent: nil

  validates :name, :pim_name, uniqueness: true
  validates :hostname, :oauth_application_id, uniqueness: true, allow_blank: true
  validates :business, :supplier_fee_mode, :single_shipping_fee, :engraving_fee, presence: true
  validates :support_email, presence: true, format: { with: CustomValidators::Emails.email_validator }
  validates :support_phone_number, format: { with: /\A\d+\z/, message: 'must be only numbers.', allow_blank: true }
  has_paper_trail ignore: %i[created_at updated_at]

  scope :by_name,   ->(name)   { where('name ILIKE :name OR pim_name ILIKE :name', name: "%#{name}%") }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_hostname_union_default, ->(hostname) { where('hostname like ? or id = ?', "%#{hostname}%", Storefront::RESERVEBAR_ID) }
  scope :inheritable, -> { where(parent_storefront: nil) }
  scope :liquidable, -> { where(is_liquid: true) }

  has_attached_file :favicon_file
  has_attached_file :logo_file
  has_attached_file :mobile_logo_file
  has_attached_file :auth0_logo_file

  validates :auth0_domain, :auth0_client_id, :auth0_client_secret,
            :auth0_audience, :auth0_db_connection, presence: { if: :auth0? }
  validates :auth_provider, inclusion: { in: auth_providers.keys }
  validates :engraving_fee, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 200 }
  validates_attachment_content_type :favicon_file, content_type: /\Aimage/
  validates_attachment_content_type :logo_file, content_type: /\Aimage/
  validates_attachment_content_type :mobile_logo_file, content_type: /\Aimage/
  validates_attachment_content_type :auth0_logo_file, content_type: /\Aimage/

  validate :cannot_inherit_tracking_page_without_parent_storefront
  validate :cannot_inherit_from_self

  accepts_nested_attributes_for :webhook

  encrypts :auth0_domain, :auth0_client_id, :auth0_client_secret, :auth0_audience, :auth0_db_connection,
           :segment_write_key, :iterable_api_key, :auth0_api_client_id, :auth0_api_client_secret, :auth0_api_domain,
           previous_versions: [{ master_key: ENV['LOCKBOX_PREV_KEY'] }].map { |prev_key|
             prev_key[:master_key].nil? ? nil : { master_key: ENV['LOCKBOX_PREV_KEY'] }
           }.compact

  before_validation do
    name&.strip!
    pim_name&.strip!
    segment_tag_id&.strip!

    # We exclude all unknown fulfillment types before validation
    fulfillment_types&.reject! { |val| FULFILLMENT_TYPES.exclude?(val) }
    fulfillment_types&.sort!
  end

  before_validation :generate_pim_name, on: :create

  after_initialize :default_values

  before_destroy do
    if !is_liquid || orders.any?
      errors.add(:base, 'cannot destroy non-liquid storefront with orders')
      throw(:abort)
    end
  end

  def favicon_url
    favicon_file&.url
  end

  def logo_url
    logo_file&.url
  end

  def mobile_logo_url
    mobile_logo_file&.url
  end

  def auth0_logo_url
    auth0_logo_file&.url
  end

  def success_page_name
    success_screen&.name
  end

  def default_storefront?
    id == MINIBAR_ID
  end

  def minibar?
    id == MINIBAR_ID
  end

  def reservebar?
    id == RESERVEBAR_ID
  end

  def getstocked?
    id == GET_STOCKED_ID
  end

  def operated_and_owned?
    minibar? || reservebar? || getstocked?
  end

  def vgm_eligible?
    enable_video_gift_message? && business.video_gift_fee&.positive?
  end

  def display_support_phone_number
    ActiveSupport::NumberHelper.number_to_phone(support_phone_number, area_code: true)
  end

  def membership_plan
    membership_plans.active.first
  end

  def normalize_friendly_id(string)
    string.delete("'").parameterize
  end

  def to_param
    id&.to_s
  end

  def generate_client_id
    3.times do
      self.client_id = SecureRandom.hex
      return unless Storefront.exists?(client_id: client_id)
    end

    errors.add :client_id, 'couldn\'t be generated'
  end

  def priority_hostname
    hostname&.split(',')&.first
  end

  private

  def cannot_inherit_tracking_page_without_parent_storefront
    errors.add(:inherits_tracking_page, 'cannot inherit tracking page without parent storefront') if inherits_tracking_page && parent_storefront.nil?
  end

  def cannot_inherit_from_self
    errors.add(:parent_storefront_id, 'cannot inherit from the same storefront') if parent_storefront.present? && parent_storefront.id == id
  end

  def generate_pim_name
    return if pim_name.present?

    self.pim_name = Storefront.maximum('"storefronts"."pim_name"::int').to_i.next.to_s.rjust(3, '0')
  end

  def permalink_candidates
    [
      [name],
      [name, '-', :uuid]
    ]
  end

  def default_values
    self.tracking_page_hostname =
      tracking_page_hostname.presence ||
      [
        [
          'order-status',
          %w[production master].include?(ENV['ENV_NAME']) ? nil : ENV['ENV_NAME']
        ].compact.join('-'),
        default_storefront? ? 'minibardelivery' : 'reservebar',
        'com'
      ].compact.join('.')
  end
end
