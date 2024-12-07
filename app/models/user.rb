# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  birth_date                :date
#  persistence_token         :string(255)
#  access_token              :string(255)
#  comments_count            :integer          default(0)
#  created_at                :datetime
#  updated_at                :datetime
#  employee_id               :integer
#  is_male                   :boolean          default(FALSE), not null
#  apn_token                 :string(255)
#  vip                       :boolean          default(FALSE), not null
#  referral_code             :string(255)
#  braintree_customer_id     :string(255)
#  corporate                 :boolean          default(FALSE), not null
#  company_name              :string(255)
#  trak_id                   :string(255)
#  utm_source                :string(255)
#  utm_medium                :string(255)
#  utm_campaign              :string(255)
#  utm_term                  :string(255)
#  utm_content               :string(255)
#  test_group                :integer
#  anonymous                 :boolean          default(FALSE), not null
#  tax_exempt                :boolean          default(FALSE), not null
#  tax_exempt_verified_at    :datetime
#  boozecarriage_eligible    :boolean
#  account_id                :integer
#  account_type              :string(255)
#  roles_mask                :integer
#  profile_id                :integer
#  one_signal_id             :string(255)
#  full_contact_profile_id   :integer
#  doorkeeper_application_id :integer
#  tax_exemption_code        :string(2)        default("custom")
#  email_subscribed          :boolean          default(FALSE)
#  sms_subscribed            :boolean          default(FALSE)
#  subscription_member       :boolean
#  liquidcommerce            :boolean          default(FALSE), not null
#  liquidcommerce_email      :string
#
# Indexes
#
#  index_users_on_access_token                 (access_token) UNIQUE
#  index_users_on_account_id_and_account_type  (account_id,account_type)
#  index_users_on_persistence_token            (persistence_token) UNIQUE
#  index_users_on_profile_id                   (profile_id)
#  index_users_on_referral_code                (referral_code) UNIQUE
#

class User < ApplicationRecord
  include User::LoyaltyMethods
  include User::MailChimp
  include User::SegmentUser
  include User::KustomerUser
  include User::ProfileData
  include User::TokenAuthentication
  include User::HasApiKeys
  include WisperAdapter
  include BarOS::Users::Hooks

  auto_strip_attributes :company_name, squish: true

  before_save :remove_company_name_if_not_corporate

  before_save :generate_referral_code
  before_create :assign_test_group

  after_create :set_attribution
  after_create :create_profile
  after_create :claim_guest_orders

  has_many :orders
  has_many :shipments, through: :orders, inverse_of: :user
  has_many :addresses, dependent: :destroy, as: :addressable
  has_many :applied_deals, through: :shipments
  has_many :billing_addresses, -> { where(active: true, address_purpose: Address.address_purposes[:billing]) }, as: :addressable, class_name: 'Address'
  has_many :cart_items
  has_many :carts, dependent: :destroy
  has_many :comments
  has_many :customer_service_comments, as: :commentable, class_name: 'Comment'
  has_many :deleted_cart_items, -> { where(active: false) }, class_name: 'CartItem'
  has_many :finished_orders, -> { finished }, class_name: 'Order'
  has_many :finished_related_orders, ->(obj) { by_email_or_contact(obj.email) }, class_name: 'Order'

  has_many :gift_details
  has_many :loyalty_transactions
  has_many :order_adjustments
  has_many :order_surveys
  has_many :payment_profiles, -> { where(active: true, reusable: true) }
  has_many :pickup_details
  has_many :purchased_items, -> { where(active: true, item_type_id: ItemType::PURCHASED_ID) }, class_name: 'CartItem'
  has_many :referrals, class_name: 'Referral', foreign_key: 'referring_user_id' # people you have tried to referred
  has_many :saved_cart_items, -> { where(active: true, item_type_id: ItemType::SAVE_FOR_LATER) }, class_name: 'CartItem'
  has_many :shipping_addresses, -> { where(active: true, address_purpose: Address.address_purposes[:shipping]) }, as: :addressable, class_name: 'Address'
  has_many :shopping_cart_items, -> { where(active: true, item_type_id: ItemType::SHOPPING_CART_ID) }, class_name: 'CartItem'
  has_many :subscriptions
  has_many :support_interactions
  has_many :visits
  has_many :authenticated_sessions
  has_many :gift_card_images, -> { where(deleted_at: nil) }
  has_many :braintree_customer_profiles

  has_one :brand_content_manager, inverse_of: :user
  has_one :brand, through: :brand_content_manager, inverse_of: :content_managers
  has_one :default_billing_address, -> { where(billing_default: true, active: true, address_purpose: Address.address_purposes[:billing]) }, as: :addressable, class_name: 'Address'
  has_one :default_shipping_address, -> { where(default: true, active: true, address_purpose: Address.address_purposes[:shipping]) }, as: :addressable, class_name: 'Address'
  has_one :employee
  has_one :referree, class_name: 'Referral', foreign_key: 'referral_user_id' # person who referred you
  has_one :sift_decision, class_name: 'Sift::Decision', as: :subject
  has_one :supplier, through: :employee

  belongs_to :account, polymorphic: true, autosave: true
  belongs_to :registered_account, foreign_key: 'account_id'
  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'
  belongs_to :profile

  enum tax_exemption_code: {
    federal: 'A',
    state: 'B',
    tribal: 'C',
    foreign: 'D',
    charitable: 'E',
    religious: 'F',
    resale: 'G',
    agricultural: 'H',
    direct_pay: 'J',
    direct_mail: 'K',
    custom: 'L',
    educational: 'M',
    local_government: 'N'
  }
  validates :tax_exemption_code, inclusion: { in: tax_exemption_codes.keys }

  validates :birth_date, birth_date: true, allow_nil: true

  delegate :supplier_id, to: :employee, allow_nil: true
  delegate :name, :email_address_with_name, :email, :first_name, :last_name, :state, :dummy_email, :latest_doorkeeper_access_token, :storefront_id, to: :account, allow_nil: true

  accepts_nested_attributes_for :addresses, :account
  accepts_nested_attributes_for :customer_service_comments, reject_if: proc { |attributes| attributes['note'].strip.blank? }

  #-----------------------------------
  # Roles Definitions
  #-----------------------------------
  include RoleModel

  # if you want to use a different integer attribute to store the
  # roles in, set it with roles_attribute :my_roles_attribute,
  # :roles_mask is the default name
  roles_attribute :roles_mask

  # declare the valid roles -- do not change the order if you add more
  # roles later, always append them at the end!
  roles :super_admin, :admin, :supplier, :customer_service, :driver, :api_developer,
        :brand_content_manager, :delivery_service, :integration_service, :credentials_admin, :api_consumer

  ADMIN_LIKE_ROLES = %i[admin super_admin customer_service].freeze

  def admin?
    roles.to_a.intersection(ADMIN_LIKE_ROLES).any?
  end

  #-----------------------------------
  # SearchKick
  #-----------------------------------
  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 200

  scope :search_import, -> { includes(:account, :addresses, :shipping_addresses) }

  def search_data
    {
      first_name: first_name,
      last_name: last_name,
      email: email,
      dummy_email: dummy_email,
      referral_code: referral_code,
      active: account&.active?,
      storefront_id: storefront_id,
      address_names: addresses.pluck(:name).uniq.compact,
      address_street: addresses.pluck(:address1).uniq.compact,
      phone_number: shipping_addresses.pluck(:phone)
                                      .uniq
                                      .reject(&:blank?)
                                      .map { |p| p.gsub(/\D/, '') }
    }
  end

  #-----------------------------------
  # Instance Methods
  #-----------------------------------

  def tax_exemption_code_value
    read_attribute_before_type_cast(:tax_exemption_code)
  end

  def account_attributes=(account_attributes)
    if account_attributes.present?
      account_attributes[:allow_no_password] = true
      self.account ||= RegisteredAccount.new(user: self)
      self.account.assign_attributes(account_attributes)
    end
  end

  def guest?
    email =~ /anonymo\.us\z/
  end

  def guest_by_email?
    index = account.read_attribute(:email) =~ /anonymo\.us\z/
    index.present?
  end

  def generate_referral_code
    # GUEST ACCOUNTS will have 10-number length temporal referral code
    # after address fill on guest checkout form, correct referral code will be set (JM12345 kind of)
    return if referral_code.present? && referral_code.to_s !~ /\A\d*\z/

    # TODO: At some point we will have all codes used for "John Smith"
    # or very usual first names/last names combinations
    if guest?
      ref_code = rand(9_999_999_999).to_s
    else
      valid_char         = ->(word) { String(word).downcase.each_char.find(&:ascii_only?) }
      char_or_default    = ->(a_to_z, fn, word) { fn.call(word) || a_to_z.sample }.curry.call(Array('a'..'z'), valid_char)

      ref_code = [char_or_default[first_name], char_or_default[last_name], String(rand(9_999_999)).rjust(6, '0')].join
    end
    if User.exists?(referral_code: ref_code)
      logger.info(message: 'user referral code collision', referral_code: ref_code)
      generate_referral_code
    else
      self.referral_code = ref_code
    end
    true
  end

  def assign_test_group
    self.test_group = rand(1..100)
  end

  def get_test_group
    if test_group.nil?
      assign_test_group
      save
    end
    test_group
  end

  def set_attribution
    user = ZipcodeWaitlist.find_by(email: email)
    if user
      update(utm_campaign: user.utm_campaign,
             utm_content: user.utm_content,
             utm_medium: user.utm_medium,
             utm_source: user.utm_source,
             utm_term: user.utm_term)
    end
  end

  def tax_exempt?(time = Time.zone.now)
    tax_exempt && time > tax_exempt_verified_at
  end

  def tax_exempt=(value)
    self[:tax_exempt] = value
    self.tax_exempt_verified_at = value ? Time.zone.now : nil
  end

  def trak?
    trak_id.present?
  end

  def last_order
    orders.finished.order(completed_at: :desc).first
  end

  def first_order
    orders.finished.order(completed_at: :asc).first
  end

  def last_supplier
    last_order&.order_suppliers&.first || shipping_addresses.first&.supplier
  end

  # returns your last cart or nil
  def current_cart
    carts.last
  end

  # formats the String
  def format_birth_date(b_date)
    self.birth_date = Date.strptime(b_date, '%m/%d/%Y').to_s(:db) if b_date.present?
  end

  def display_birth_date
    birth_date ? I18n.localize(birth_date, format: :us_date) : 'N/A'
  end

  def display_gender
    is_male ? 'Male' : 'Female'
  end

  # formats the String
  #
  # @param [String] formatted in Euro-time
  # @return [ none ]  sets birth_date for the user
  def form_birth_date
    birth_date.present? ? birth_date.strftime('%m/%d/%Y') : nil
  end

  # formats the String
  #
  # @param [String] formatted in Euro-time
  # @return [ none ]  sets birth_date for the user
  def form_birth_date=(val)
    self.birth_date = Date.strptime(val, '%m/%d/%Y').to_s(:db) if val.present?
  end

  # paginated results from the admin User grid
  #
  # @param [Optional params]
  # @return [ Array[User] ]
  # TODO JM: This can be done so much more effectively if you drop the .all from user as that is loading all the records onece
  # you just need User so you can lazy load the records. Here you are instantiating all the Users, then throwing that away and
  # instantiating them based on a scope.
  def self.admin_grid(params = {})
    grid = User.all
    grid = grid.joins('INNER JOIN registered_accounts ON registered_accounts.id = users.account_id')
    grid = grid.where('lower(registered_accounts.first_name) LIKE ?', "#{params[:first_name].downcase.squish}%") if params[:first_name].present?
    grid = grid.where('lower(registered_accounts.last_name) LIKE ?',  "#{params[:last_name].downcase.squish}%")  if params[:last_name].present?
    grid = grid.where('registered_accounts.storefront_id = ?', params[:storefront_id]) if params[:storefront_id].present?
    if params[:email].present?
      grid = grid.where('registered_accounts.email = ?', params[:email].downcase.squish)
                 .or(grid.where('registered_accounts.contact_email = ?', params[:email].downcase.squish))
    end
    if params[:roles].present?
      roles_count = User.valid_roles.count
      role_bit_locations = params[:roles].map { |role| roles_count - User.valid_roles.find_index(role.to_sym) }
      role_bit_locations.each_with_index do |role_bit_location, index|
        query = 'substring(users.roles_mask::bit(?)::varchar, ?, 1)::int = 1'
        grid = index.zero? ? grid.where(query, roles_count, role_bit_location) : grid.or(User.where(query, roles_count, role_bit_location))
      end
    end
    grid = grid.search(params[:search]) if params[:search].present?
    grid
  end

  def number_of_finished_orders
    finished_orders.count
  end

  def finished_an_order?
    finished_orders.exists?
  end

  def nth_order?(count)
    finished_orders.count == count
  end

  def number_of_finished_orders_at(at)
    finished_orders.count { |o| o.completed_at < at }
  end

  def first_last_initial
    "#{first_name} #{last_name[0]}."
  end

  def allows_push_notifications?
    !partner_api_user?
  end

  def allows_delivery_estimate_push_notifications?
    allows_push_notifications? && Feature[:delivery_estimate_onesignal].enabled?(self)
  end

  def partner_api_user?
    doorkeeper_application && !doorkeeper_application.name.downcase.include?('minibar')
  end

  # takes in supplier id, assigns the user as an employee of that supplier
  def employee_of_supplier(supplier_id)
    RegisteredAccountTokenRevocationWorker.perform_async(account_id)

    if supplier_id.blank? && employee.present?
      employee.destroy
    elsif Supplier.exists?(supplier_id) && has_any_role?(:driver, :supplier) # see if supplier exists and user has the supplier role
      create_employee(supplier_id: supplier_id) if employee.nil?
      employee.update(supplier_id: supplier_id, active: true)
    end
  end

  def remove_company_name_if_not_corporate
    self.company_name = nil if (corporate_changed? || company_name_changed?) && (corporate.blank? && company_name.present?)
  end

  def previous_order_items_cache_key
    "user:#{id}:previous_order_items"
  end

  def previous_order_items
    Rails.cache.fetch(previous_order_items_cache_key, expires_in: 24.hours) do
      orders.processed.joins(order_items: { variant: :product })
            .merge(Variant.non_gift_cards)
            .pluck('distinct products.product_grouping_id')
            .compact
    end
  end

  def invalidate_previous_order_items_cache!
    Rails.cache.delete(previous_order_items_cache_key)
  end

  def flipper_id
    "User:#{id}"
  end

  def gift_cards
    # This should be a relationship but email is inside registered account and
    # account.coupon doesn't feels right. Change this when we need to eager-load or query it
    Coupon.where(recipient_email: email)
  end

  def corporate_email?
    email !~ /edu$/ && !PublicEmail.email_is_public?(email)
  end

  def minibar?
    account&.storefront&.business&.default_business?
  end

  def anonymize
    account.anonymize

    update(one_signal_id: nil)

    addresses.map(&:anonymize)

    orders.each do |order|
      order.update(email: email)
    end

    payment_profiles.each do |payment_profile|
      payment_profile.update(first_name: first_name, last_name: last_name)
    end
  end

  private

  # Upon user registration or conversion (by setting a password), consolidate previous guest orders with the same email (if any).
  def claim_guest_orders
    return unless account
    return if ENV['ENV_NAME'] != 'master'

    Order::ClaimGuestOrdersWorker.perform_async(account.id)
  end
end
