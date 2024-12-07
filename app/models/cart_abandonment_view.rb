# frozen_string_literal: true
# == Schema Information
#
# Table name: cart_abandonments
#
#  order_id                     :integer          primary key
#  user_id                      :integer
#  client                       :string(255)
#  updated_at                   :datetime
#  state                        :string(255)
#  user_same_day_most_recent    :boolean
#  user_same_day_finished_order :boolean
#

# frozen_string_literal: true

# TODO: This view can be slow - can we optimize and/or add indices?

class CartAbandonmentView < ActiveRecord::Base
  self.table_name  = 'cart_abandonments'
  self.primary_key = 'order_id'

  ABANDONED_THRESHOLD = 30.minutes
  SUPPLIER_CLOSED_BUFFER = 30.minutes
  EMAIL_SENT_KEY_BASE = 'EMAIL_SENT_TO_USER'
  NOTIFY_CATEGORIES = %w[wine beer liquor mixers].freeze

  belongs_to :order
  belongs_to :user
  has_many :order_suppliers, through: :order

  # last updated today, but not for some time
  scope :abandoned_today, -> { where(updated_at: Time.current.beginning_of_day..Time.current - ABANDONED_THRESHOLD) }

  # use doorkeeper_application_id instead of client here?
  scope :web_order, -> { where(client: 'Minibar - Web Store') }

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------

  def self.eligible_to_notify
    web_order.includes(:order).abandoned_today.select do |abandonment|
      !abandonment.user_notified_today? &&
        !abandonment.user.partner_api_user? &&
        abandonment.all_suppliers_valid? &&
        abandonment.eligible_order_items?
    end
  end

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------

  def eligible_order_items?
    order&.order_items&.one? ? CartAbandonmentView::NOTIFY_CATEGORIES.include?(order.order_items.first.product.hierarchy_category.name) : true
  end

  def user_notified_today?
    redis_store.exists(user_redis_key)
  end

  def mark_user_notified_today
    redis_store.set(user_redis_key, Time.zone.now) # setting it to the current timestamp
    redis_store.expireat(user_redis_key, end_of_day_timestamp)
  end

  def all_suppliers_valid?
    # must be open now and for the duration of the buffer
    order_suppliers.all? { |s| s.open_until?(Time.zone.now.in_time_zone(s.timezone) + SUPPLIER_CLOSED_BUFFER) }
  end

  private

  def redis_store
    @redis_store ||= RedisStoreService.new(self.class.name)
  end

  def user_redis_key
    "#{EMAIL_SENT_KEY_BASE}::#{user_id}"
  end

  def end_of_day_timestamp
    Time.zone.now.end_of_day.to_i
  end
end
