# == Schema Information
#
# Table name: fraudulent_orders
#
#  id                  :integer          not null, primary key
#  order_id            :integer
#  created_at          :datetime
#  updated_at          :datetime
#  payment_fraud_type  :integer
#  cancel_account      :boolean          default(FALSE)
#  block_device        :boolean          default(FALSE)
#  chargeback_reported :boolean          default(FALSE)
#  user_id             :integer
#  related_user_ids    :integer          default([]), is an Array
#
# Indexes
#
#  index_fraudulent_orders_on_order_id  (order_id)
#

class FraudulentOrder < ActiveRecord::Base
  belongs_to :order, touch: true

  enum payment_fraud_type: {
    pending: 0,
    payment_fraud: 1,
    account_takeover: 2,
    unrecognized_charge: 3,
    promo_abuse: 4
  }

  validate :user_should_not_have_active_membership

  after_commit :process_chargeback, on: :create
  after_save :act_on_accounts
  after_save :process_decisions, if: :payment_fraud_type_changed?

  #-----------------------------------
  # SearchKick
  #-----------------------------------
  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 200,
             text_start: [:associated_addresses],
             word_start: [:item_names]

  scope :search_import, -> { includes(order: [:order_items]) }

  def search_data
    {
      associated_addresses: order.user.addresses.map(&:full_street_address).uniq.compact,
      associated_names: order.user.addresses.map(&:name).uniq.compact,
      associated_phone: order.user.addresses.map { |a| a.phone.to_s.gsub(/\W+/, '') }.compact.uniq,
      customer_email: order.email,
      customer_name: order.user.name,
      ip_addresses: [order.ip_address],
      item_names: order.order_items.map { |oi| oi.product.name }.uniq.compact
    }
  end

  #-----------------------------------
  # Instance Methods
  #-----------------------------------
  def type_editable?
    payment_fraud_type.nil? || pending?
  end

  def process_chargeback
    return unless chargeback_reported

    order.disputes.create(kind: :chargeback, status: :lost, reason: :fraud, transaction_id: order.charges.first&.transaction_id)
  end

  def act_on_accounts
    user_ids = related_user_ids.dup
    if related_user_ids_changed?
      (old_ids, new_ids) = changes[:related_user_ids]
      act_on_old_accounts(old_ids - new_ids)
      act_on_new_accounts(new_ids - old_ids)
      user_ids = old_ids & new_ids
    end

    user_ids << order.user_id

    user_ids.each do |user_id|
      process_account_cancelation(user_id) if cancel_account_changed?
      process_device_block(user_id)        if block_device_changed?
    end
  end

  def act_on_old_accounts(user_ids)
    user_ids.each { |user_id| UserAccountActivationWorker.perform_async(user_id) } if cancel_account_was
    user_ids.each { |user_id| DeviceBlacklistRemovalWorker.perform_async(user_id) } if block_device_was
  end

  def act_on_new_accounts(user_ids)
    user_ids.each { |user_id| UserAccountCancelationWorker.perform_async(user_id) } if cancel_account
    user_ids.each { |user_id| DeviceBlacklistWorker.perform_async(user_id) } if block_device
  end

  def process_account_cancelation(user_id)
    cancel_account ? UserAccountCancelationWorker.perform_async(user_id) : UserAccountActivationWorker.perform_async(user_id)
  end

  def process_decisions
    Fraud::Decision.new(
      analyst: User.find_by(id: user_id)&.email,
      order_number: order.number,
      source: chargeback_reported ? :chargeback : :manual_review,
      type: :fraud,
      user_id: order.user.referral_code
    ).call_async
  end

  def process_device_block(user_id)
    block_device ? DeviceBlacklistWorker.perform_async(user_id) : DeviceBlacklistRemovalWorker.perform_async(user_id)
  end

  private

  def user_should_not_have_active_membership
    return unless cancel_account

    return if Membership.active.where(user_id: user_id).blank?

    errors.add(:user, "can't have an active membership")
  end

  def ip_addresses
    ip_addresses = []
    ip_addresses << order.ip_address
    ip_addresses << order.user.account.last_sign_in_ip.to_s
    ip_addresses << order.user.account.current_sign_in_ip.to_s
    ip_addresses.uniq.compact
  end
end
