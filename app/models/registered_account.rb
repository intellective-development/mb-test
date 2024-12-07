# frozen_string_literal: true

# == Schema Information
#
# Table name: registered_accounts
#
#  id                          :integer          not null, primary key
#  email                       :string(255)      default(""), not null
#  encrypted_password          :string(255)      default(""), not null
#  reset_password_token        :string(255)
#  reset_password_sent_at      :datetime
#  remember_created_at         :datetime
#  sign_in_count               :integer          default(0), not null
#  current_sign_in_at          :datetime
#  last_sign_in_at             :datetime
#  current_sign_in_ip          :inet
#  last_sign_in_ip             :inet
#  created_at                  :datetime
#  updated_at                  :datetime
#  password_salt               :string(255)
#  first_name                  :string(255)
#  last_name                   :string(255)
#  state                       :string(255)
#  provider                    :string
#  uid                         :string
#  failed_attempts             :integer          default(0), not null
#  unlock_token                :string
#  locked_at                   :datetime
#  contact_email               :string
#  ato_email_sent_at           :datetime
#  storefront_id               :bigint(8)
#  storefront_account_id       :string
#  phone_number                :string
#  contact_phone_number        :string
#  shopify_customer_gid        :string
#  storefront_account_login_id :string
#
# Indexes
#
#  index_reg_accs_on_shopify_customer_gid_and_storefront_id  (shopify_customer_gid,storefront_id) UNIQUE
#  index_registered_accounts_on_contact_email                (contact_email)
#  index_registered_accounts_on_email_and_storefront_id      (email,storefront_id) UNIQUE
#  index_registered_accounts_on_reset_password_token         (reset_password_token) UNIQUE
#  index_registered_accounts_on_storefront_account_id        (storefront_account_id)
#  index_registered_accounts_on_storefront_account_login_id  (storefront_account_login_id)
#  index_registered_accounts_on_uid                          (uid)
#  index_registered_accounts_on_unlock_token                 (unlock_token) UNIQUE
#  registered_accounts_contact_email_idx                     (contact_email)
#  registered_accounts_last_name_idx                         (last_name)
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#

class RegisteredAccount < ActiveRecord::Base
  include TempStorefrontDefault
  include WisperAdapter
  include User::PasswordAuthentication
  include ServiceAccounts

  validate :user_should_not_have_active_membership, on: :update, if: :state_changed?

  has_one :user, as: :account, autosave: true
  has_many :login_activities, as: :user # use :user no matter what your model name
  has_many :login_providers
  belongs_to :storefront, optional: false

  phony_normalize :phone_number

  delegate :access_token, to: :user, allow_nil: true
  delegate :id, to: :user, prefix: true, allow_nil: true
  delegate :email_subscribed, to: :user
  delegate :sms_subscribed, to: :user

  after_commit :publish_registered_account_created, on: :create
  after_save :claim_guest_orders

  # Since ActiveUser's #user is redefined below we need an alias validate whether a user record is already present or not.
  alias active_record_user user
  after_save :touch_user, if: -> { active_record_user && !active_record_user.new_record? }

  #-----------------------------------
  # Class methods
  #-----------------------------------
  class << self
    def guests
      where('contact_email IS NOT NULL AND contact_email != email')
        .or(where('contact_phone_number IS NOT NULL'))
    end

    def email_exists?(storefront, contact_email, email)
      (contact_email && exists?(storefront: storefront, email: contact_email.downcase)) ||
        exists?(storefront: storefront, email: email.downcase)
    end
  end
  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def publish_registered_account_created
    broadcast_event(:created, prefix: true)
  end

  # TODO: JM: This should be dumped into a helper. Display code doesn't belong here.
  def email_address_with_name
    "\"#{name}\" <#{email}>"
  end

  def dummy_email
    "u+#{user.referral_code}@dummymail.net"
  end

  def user
    super || build_user
  end

  def name
    first_name? && last_name? ? [first_name, last_name].join(' ') : email
  end

  def guest?
    contact_email.present? || contact_phone_number.present?
  end

  def customer?
    !guest?
  end

  def dummy?
    email.match(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}@(minibardelivery.com|anonymo.us)/)
  end

  def email
    guest? ? contact_email : super
  end

  def ato_email_sent
    update(ato_email_sent_at: Time.zone.now) unless ato_email_sent_at
  end

  def ato_email_cleared
    update(ato_email_sent_at: nil)
  end

  def latest_doorkeeper_access_token(application_id)
    access_token = Doorkeeper::AccessToken.where(resource_owner_id: id, application_id: application_id, revoked_at: nil).last
    access_token unless access_token&.expires_in && Time.zone.now > access_token.created_at + access_token.expires_in.seconds
  end

  def liquid_account?
    provider == 'liquid:auth0'
  end

  def anonymize
    contact = "#{rand(10_000..99_999)}@no-email.test" unless contact_email.nil?
    update(
      email: "#{rand(99_999)}@no-email.test",
      first_name: "Anonymous#{rand(99_999)}",
      last_name: "Anonymous#{rand(99_999)}",
      contact_email: contact
    )
  end

  private

  def touch_user
    user.touch
  end

  # Upon guest checkout, consolidate previous guest orders with the same email (if any).
  def claim_guest_orders
    return unless contact_email_changed?

    Order::ClaimGuestOrdersWorker.perform_async(id)
  end

  def user_should_not_have_active_membership
    return unless canceled?
    return if Membership.active.where(user: user).blank?

    errors.add(:user, "can't have an active membership")
  end
end
