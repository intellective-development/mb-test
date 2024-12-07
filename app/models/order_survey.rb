# == Schema Information
#
# Table name: order_surveys
#
#  id         :integer          not null, primary key
#  token      :string(255)
#  score      :integer
#  comment    :text
#  user_id    :integer          not null
#  order_id   :integer          not null
#  state      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_order_surveys_on_order_id              (order_id)
#  index_order_surveys_on_state_and_updated_at  (state,updated_at)
#  index_order_surveys_on_token                 (token)
#  index_order_surveys_on_user_id               (user_id)
#

class OrderSurvey < ActiveRecord::Base
  include Wisper::Publisher

  belongs_to :user
  belongs_to :order

  has_many :order_survey_suppliers
  has_many :suppliers, through: :order_survey_suppliers
  has_many :order_survey_responses
  has_many :order_survey_reasons, through: :order_survey_responses

  after_create :generate_token

  validates :user_id,   presence: true
  validates :order_id,  presence: true, uniqueness: true
  validates :score, inclusion: { in: [nil, 0, 1, 2, 3, 4, 5] }

  state_machine initial: :pending do
    state :started
    state :completed
    state :expired

    event :start do
      transition to: :started, from: :pending
    end

    event :complete do
      transition to: :completed, from: %i[started pending]
    end

    event :expire do
      transition to: :expired, from: :pending
    end

    after_transition to: :started,   do: [:publish_order_survey_started]
    after_transition to: :completed, do: [:publish_order_survey_completed]
  end

  scope :pending,         -> { where(state: 'pending') }
  scope :started,         -> { where(state: 'started') }
  scope :complete,        -> { where(state: 'completed') }
  scope :expired,         -> { where(state: 'expired') }
  scope :last_sixty_days, -> { where('updated_at > ?', 60.days.ago) }
  scope :with_score,      -> { where.not(score: 0) }

  def self.prepare(order)
    # Create and return the new survey
    survey = OrderSurvey.new(order_id: order.id, user_id: order.user.id)
    order.order_suppliers.each { |s| survey.order_survey_suppliers.create(supplier_id: s.try(:id)) } if survey.save
    survey
  end

  def self.expire_pending
    OrderSurvey.pending.where('created_at < ?', 21.days.ago).map(&:expire!)
  end

  def self.expire_pending_for_user(user_id)
    OrderSurvey.pending.where(user_id: user_id).map(&:expire!)
  end

  def self.response_rate
    (100 / OrderSurvey.count.to_f) * OrderSurvey.complete.count
  end

  def self.survey_time(order)
    time = if order.shipments.any?(&:scheduled_for)
             order.shipments.maximum(:scheduled_for).in_time_zone(order.shipments.first.supplier.timezone)
           else
             order.completed_at
           end
    time + Settings.order_survey_delay.hours
  end

  def publish_order_survey_started
    broadcast(:order_survey_started, self)
  end

  def publish_order_survey_completed
    broadcast(:order_survey_completed, self)
  end

  def freshdesk_params
    {
      subject: "#{score}-Star Order Survey",
      description: "Reasons: #{reason_names}\n\nFeedback from survey: \n\n#{comment}",
      name: user.name,
      email: user.email
    }
  end

  def eligible_for_app_review?
    (order.client == 'Minibar - iOS (RN)') && (score == 5) && (user.order_surveys.where(score: 5).size == 1)
  end

  def escalate?
    comment.present? || (score < 3 && score.positive?)
  end

  def reason_names
    text = order_survey_reasons.pluck(:name).join(',')
    text.presence || 'None Provided'
  end

  private

  def generate_token
    token = SecureRandom.urlsafe_base64(32)
    OrderSurvey.find_by(token: token).nil? ? update(token: token) : generate_token
  end
end
