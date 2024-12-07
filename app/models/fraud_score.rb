# == Schema Information
#
# Table name: fraud_scores
#
#  id                :integer          not null, primary key
#  value             :float
#  results           :json
#  order_id          :integer          not null
#  created_at        :datetime
#  updated_at        :datetime
#  ml_confidence     :float            default(0.0)
#  ml_prediction     :boolean
#  today_order_count :integer          default(0)
#
# Indexes
#
#  index_fraud_scores_on_order_id  (order_id)
#

class FraudScore < ActiveRecord::Base
  include Wisper::Publisher

  belongs_to :order

  has_one :user, through: :order

  after_create :process_fraud_score

  #--------------------------------------------------
  # Weightings & Multipliers
  #--------------------------------------------------

  DAILY_ORDER_THRESHOLD = 1

  SCORE_WEIGHTINGS = {
    check_previous_fraud: 100,
    check_non_us_ip_address: 10,
    check_out_of_state_billing: 20,
    check_different_name: 5,
    check_different_address1: 10,
    check_zip_code_not_in_state: 25,
    check_business_address: -20,
    check_multiple_orders_today: 40
  }.freeze

  SCORE_MULTIPLIERS = {
    check_products: 4
  }.freeze

  #--------------------------------------------------
  # Instance Methods
  #--------------------------------------------------

  def process_fraud_score
    return if Rails.env.test?

    self.results = perform_checks.as_json
    self.value   = calculate_score
    self.order   = order
    self.today_order_count = order.user.orders.finished.where(completed_at: order.completed_at.beginning_of_day..order.completed_at).size
    save!
  end

  def perform_checks
    methods.select { |name| name.to_s.starts_with?('check_') }.each do |method|
      results[method] = send(method)
    end
    results
  end

  def calculate_score(score = 0)
    unless results['check_whitelist'] || results['check_established_customer']
      results.each do |key, value|
        score += SCORE_WEIGHTINGS[key.to_sym] if SCORE_WEIGHTINGS[key.to_sym] && value
        score += value * SCORE_MULTIPLIERS[key.to_sym] if SCORE_MULTIPLIERS[key.to_sym] && value
      end
    end
    score
  end

  def flagged?
    ml_prediction || secondary_fraud_check?
  end

  def secondary_fraud_check?
    return false if order.user.vip? || order.user.corporate?
    return false if order.user.created_at < 30.days.ago

    (today_order_count || 0) > DAILY_ORDER_THRESHOLD
  end

  #--------------------------------------------------
  # Fraud Checks
  #--------------------------------------------------

  def check_whitelist
    order.vip? || user.corporate?
  end

  def check_established_customer
    return false if user.finished_orders.where('completed_at < ?', 30.days.ago).count < 2

    true
  end

  def check_non_us_ip_address
    order.ip_geolocation.blank? ? false : order.ip_geolocation != 'US'
  end

  def check_products
    order_items = order.order_items.map { |i| i.variant.product_name }
    results = FraudulentOrder.search('*',
                                     where: {
                                       item_names: order_items
                                     },
                                     aggs: [:item_names],
                                     smart_aggs: false)

    return 0 unless results.any?

    total_results = results.size.to_f
    total_high_risk_items = results.aggs['item_names']['buckets'].sum { |b| b['doc_count'].to_f }
    unique_high_risk_items = results.aggs['item_names']['buckets'].size.to_f

    total_results / (total_high_risk_items / unique_high_risk_items)
  end

  def check_business_address
    order.ship_address&.business?
  end

  def check_out_of_state_billing
    shipment = order.shipments.first
    return false if shipment.digital? && shipment.supplier.address.nil?
    return false if order.payment_profile.nil?

    shipment&.supplier && !String(shipment.supplier.address.state_name).casecmp(String(order.payment_profile.address.state_name).downcase).zero?
  end

  def check_different_zip_codes
    return false if order.ship_address.nil? || order.payment_profile.nil?

    order.ship_address&.zip_code != order.payment_profile.address.zip_code
  end

  def check_zip_code_not_in_state
    return false if order.payment_profile.nil?

    order.payment_profile.address.zip_code.to_region(state: true) != order.payment_profile.address.state_name
  end

  def check_different_address1
    return false if order.ship_address.nil? || order.payment_profile.nil?

    !order.ship_address.address1.squish.casecmp(order.payment_profile.address.address1.squish.downcase).zero?
  end

  def check_different_name
    return false if order.payment_profile.nil?

    order.user_name.downcase.squish != order.payment_profile.address.name.downcase.squish
  end

  def check_previous_fraud
    return false unless order.ship_address

    results = FraudulentOrder.search([String(order.ship_address&.phone).gsub(/\W+/, ''), order.ip_address, order.email].join(' '),
                                     fields: [{ customer_email: :exact },
                                              { ip_addresses: :exact },
                                              { associated_phone: :exact }],
                                     operator: 'or')
    results.any?
  end

  def check_multiple_orders_today
    order.user.finished_orders.where('completed_at > ?', 1.day.ago).count > 1
  end
end
