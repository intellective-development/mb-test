# == Schema Information
#
# Table name: payment_profiles
#
#  id                        :integer          not null, primary key
#  user_id                   :integer
#  address_id                :integer
#  default                   :boolean
#  active                    :boolean          default(TRUE), not null
#  created_at                :datetime
#  updated_at                :datetime
#  last_digits               :string(255)
#  month                     :string(255)
#  year                      :string(255)
#  cc_type                   :string(255)
#  first_name                :string(255)
#  last_name                 :string(255)
#  braintree_token           :string(255)
#  doorkeeper_application_id :integer
#  bin                       :string(6)
#  reusable                  :boolean          default(TRUE)
#  deleted_at                :datetime
#  cc_kind                   :string(20)
#  payment_type              :string           default("CREDIT_CARD")
#  liquidcommerce            :boolean          default(FALSE), not null
#
# Indexes
#
#  index_payment_profiles_on_address_id  (address_id)
#  index_payment_profiles_on_user_id     (user_id)
#

class PaymentProfile < ApplicationRecord
  CREDIT_CARD = 'CREDIT_CARD'.freeze
  APPLE_PAY = 'APPLE_PAY'.freeze
  PAYPAL = 'PAYPAL'.freeze
  AFFIRM = 'AFFIRM'.freeze
  CREDIT_CARD_METHODS = [CREDIT_CARD, AFFIRM].freeze
  TOKEN_PAYMENT_METHODS = [APPLE_PAY, PAYPAL, AFFIRM].freeze
  PAYMENT_TYPES = [CREDIT_CARD, APPLE_PAY, PAYPAL, AFFIRM].freeze

  belongs_to :address
  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'
  belongs_to :user, optional: false
  has_many :orders
  has_many :memberships, inverse_of: :payment_profile, dependent: nil

  scope :active,    -> { where(active: true) }
  scope :inactive,  -> { where(active: false, deleted_at: nil) }
  scope :deleted,  -> { where.not(deleted_at: nil) }
  scope :reusable, -> { where(reusable: [true, nil]) }
  scope :credit_card, -> { where(payment_type: CREDIT_CARD) }
  scope :apple_pay, -> { where(payment_type: APPLE_PAY) }
  scope :paypal, -> { where(payment_type: PAYPAL) }

  # This ordering is used by the API when returning a users addresses - in cases such as
  # Alexa the client is using the first item in the array, so we are ensuring that
  # this is always the default address for the application in question.
  scope :ordered_by_client, ->(id) { order("CASE payment_profiles.doorkeeper_application_id WHEN #{id} THEN 1 ELSE 2 END ASC").order(default: :desc).order(updated_at: :desc) }
  scope :ordered_by_most_recent, -> { order(updated_at: :desc) }
  scope :order_by_default, -> { order(default: :desc) }
  scope :order_by_client_recency, ->(id) { joins('LEFT OUTER JOIN orders on orders.bill_address_id = payment_profiles.id').order("CASE payment_profiles.doorkeeper_application_id WHEN #{id} THEN 1 ELSE 2 END ASC").order(default: :desc).order('orders.completed_at DESC NULLS LAST') }
  scope :order_by_recently_used, -> { joins('LEFT OUTER JOIN orders on orders.bill_address_id = payment_profiles.id').order('orders.completed_at DESC NULLS LAST') }

  with_options if: :credit_card? do
    validates :cc_type,         presence: true, length: { maximum: 60 }
    validates :last_digits,     presence: true, length: { maximum: 10 }
    validates :month,           presence: true, length: { maximum: 6 }
    validates :year,            presence: true, length: { maximum: 6 }
  end

  after_commit :replace_old_defaults, if: -> { default? }

  def name
    [cc_type, last_digits].join(' - ')
  end

  def deactivate
    update(active: false)
  end

  def expired?
    Time.zone.parse("#{month}/01/#{year}").end_of_month.past?
  end

  def replace_old_defaults
    user.payment_profiles.where.not(id: id).update_all(default: false)
  end

  def bin
    return attributes['bin'] if attributes['bin'].present?
    return backfill_bin_code if credit_card?

    nil
  end

  def credit_card?
    payment_type == CREDIT_CARD
  end

  def paypal?
    payment_type == PAYPAL
  end

  private

  def backfill_bin_code
    gateway = PaymentGateway::Configuration.new(business: user&.account&.storefront&.business, payment_type: payment_type).gateway
    card = gateway.credit_card.find(braintree_token)
    update(bin: card.bin)

    card.bin
  rescue Braintree::BraintreeError => e
    notify_sentry_and_log(e, "Backfill bin code error: #{e.class.name}", { tags: { message: e.message } })
    nil
  end
end
