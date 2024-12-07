# == Schema Information
#
# Table name: sift_decisions
#
#  id           :integer          not null, primary key
#  subject_id   :integer
#  subject_type :string
#  decision_id  :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_sift_decisions_on_subject_id_and_subject_type  (subject_id,subject_type)
#

class Sift::Decision < ActiveRecord::Base
  include WisperAdapter

  self.table_name = 'sift_decisions'

  belongs_to :subject, polymorphic: true

  PAYMENT_ABUSE_NEGATIVE_DECISION_IDS = %w[order_looks_bad_payment_abuse looks_bad_payment_abuse].freeze
  PAYMENT_ABUSE_POSITIVE_DECISION_IDS = %w[order_looks_ok_payment_abuse looks_ok_payment_abuse storefront_fraud_bypass_payment_abuse].freeze

  after_commit :publish_decision_created, on: %i[create update]

  def cleared?
    PAYMENT_ABUSE_POSITIVE_DECISION_IDS.include?(decision_id)
  end

  def fraud?
    PAYMENT_ABUSE_NEGATIVE_DECISION_IDS.include?(decision_id)
  end

  def applicable_orders
    case subject_type
    when 'Order' then Array(subject)
    when 'User'  then subject.orders.where(completed_at: (updated_at - 2.hours)..updated_at)
    else []
    end
  end

  private

  def publish_decision_created
    broadcast(:decision_created, self)
  end
end
