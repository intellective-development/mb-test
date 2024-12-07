# == Schema Information
#
# Table name: subscriptions
#
#  id                 :uuid             not null, primary key
#  base_order_id      :integer
#  payment_profile_id :integer
#  user_id            :integer
#  last_order_id      :integer
#  order_count        :integer          default(1)
#  interval           :integer
#  reminders          :boolean          default(TRUE), not null
#  next_order_date    :datetime
#  state              :string(255)      default("active")
#  created_at         :datetime
#  updated_at         :datetime
#
# Indexes
#
#  index_subscriptions_on_base_order_id  (base_order_id)
#  index_subscriptions_on_user_id        (user_id)
#

class Subscription < ActiveRecord::Base
  include WisperAdapter

  has_paper_trail ignore: [:order_count]

  belongs_to :user
  belongs_to :payment_profile
  belongs_to :base_order, class_name: 'Order'
  belongs_to :last_order, class_name: 'Order'

  has_many :orders

  before_create :set_initial_values
  after_create :publish_subscription_activated

  scope :active, -> { where(state: 'active') }
  scope :next_order_date, ->(date_range) { where(next_order_date: date_range) }
  scope :search_user, lambda { |search_term|
    joins(:user)
      .joins("LEFT JOIN registered_accounts ON users.account_type = 'RegisteredAccount' AND users.account_id = registered_accounts.id")
      .where('(registered_accounts.first_name LIKE :search) or (registered_accounts.last_name LIKE :search) OR ' \
             "(registered_accounts.first_name || ' ' || registered_accounts.last_name LIKE :search) OR registered_accounts.email LIKE :search",
             search: search_term)
  }

  state_machine initial: :active do
    state :active
    state :inactive
    state :failed
    state :canceled

    event :deactivate do
      transition to: :inactive, from: %i[active failed]
    end

    event :activate do
      transition to: :active, from: %i[inactive failed]
    end

    event :failed do
      transition to: :failed, from: %i[active inactive]
    end

    event :cancel do
      transition to: :canceled, from: %i[active inactive failed]
    end

    after_transition to: :active, do: [:publish_subscription_activated]
    after_transition to: :inactive, do: [:publish_subscription_deactivated]
    after_transition to: :failed, do: [:publish_subscription_failed]
    after_transition to: :canceled, do: [:publish_subscription_canceled]

    before_transition to: :active, do: [:set_next_order_date]
  end

  #-----------------------------------
  # Class methods
  #-----------------------------------
  # Subscriptions which are due tomorrow which require notification.
  def self.to_notify
    active.next_order_date(Date.tomorrow.beginning_of_day..Date.tomorrow.end_of_day)
  end

  # Subscriptions which are due today which require processing.
  def self.to_process
    active.next_order_date(Time.zone.today.beginning_of_day..Time.zone.today.end_of_day)
  end

  def self.filter(params = {})
    params[:search_term].present? ? search_user(params[:search_term]) : self
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def process!
    SubscriptionService.process_subscription(self) if active?
  rescue StandardError => e
    # https://minibar.atlassian.net/browse/TECH-2971 try to process in next scheduling period
    set_next_order_date
    save
    broadcast(:subscription_failure, self, e.message)
  end

  def publish_subscription_activated
    broadcast_event(:activated, prefix: true) if active?
  end

  def publish_subscription_deactivated
    broadcast_event(:deactivated, prefix: true)
  end

  def publish_subscription_failed
    broadcast_event(:failed, prefix: true)
  end

  def publish_subscription_canceled
    broadcast_event(:canceled, prefix: true)
  end

  def publish_subscription_reminder
    broadcast_event(:reminder, prefix: true)
  end

  def increment_order_count
    self.order_count += 1
  end

  def set_initial_values
    self.last_order_id = base_order.id
    self.payment_profile = base_order.payment_profile
    self.user = base_order.user

    set_next_order_date if next_order_date.nil?
  end

  def set_next_order_date
    scheduled_for = last_order.scheduled_for
    scheduled_for ||= last_order.shipments.first.scheduled_for if last_order.shipments&.first

    self.next_order_date = (scheduled_for || last_order.created_at).beginning_of_hour + interval.days

    # Handling the case where a subscription has been paused and the
    # next_order date is in the past.
    # TODO: Do we need to change this to be the same day
    self.next_order_date = interval.days.since.beginning_of_hour if next_order_date.past?
  end
end
