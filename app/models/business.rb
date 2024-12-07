# == Schema Information
#
# Table name: businesses
#
#  id                                    :integer          not null, primary key
#  name                                  :string
#  service_fee                           :decimal(9, 2)
#  price_rounding                        :integer          default("none"), not null
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  fee_supplier_permalink                :string
#  product_supplier_permalink            :string
#  video_gift_fee                        :decimal(9, 2)    default(0.0)
#  braintree_cse_key_ciphertext          :text
#  braintree_merchant_id_ciphertext      :text
#  braintree_private_key_ciphertext      :text
#  braintree_public_key_ciphertext       :text
#  braintree_tokenization_key_ciphertext :text
#  avalara_company_code                  :string
#  bevmax_partner_name                   :string
#  bevmax_account_id                     :string
#  bevmax_channel_id                     :string
#
# Indexes
#
#  index_businesses_on_name  (name) UNIQUE
#
class Business < ActiveRecord::Base
  MINIBAR_ID    = 1
  RESERVEBAR_ID = 2

  encrypts :braintree_cse_key, :braintree_merchant_id, :braintree_private_key,
           :braintree_public_key, :braintree_tokenization_key,
           previous_versions: [{ master_key: ENV['LOCKBOX_PREV_KEY'] }].map { |prev_key|
             prev_key[:master_key].nil? ? nil : { master_key: ENV['LOCKBOX_PREV_KEY'] }
           }.compact

  has_many :storefronts

  enum price_rounding: { none: 0, half_nine: 1, whole: 2 }, _prefix: :price_rounding

  validates :name, uniqueness: true
  validates :fee_supplier_permalink, :product_supplier_permalink, presence: true
  validate :valid_permalinks

  has_paper_trail ignore: %i[created_at updated_at]

  scope :by_name, ->(name) { where('name ILIKE :name', name: "%#{name}%") }

  def round(value)
    return value if price_rounding_none?
    return value.ceil if price_rounding_whole?
    return 0.0 if value == 0.01
    return value if value.modulo(1).zero?
    return value.floor + 0.49 if value <= value.floor + 0.49

    value.floor + 0.99
  end

  def fee_supplier
    Supplier.find_by(permalink: fee_supplier_permalink)
  end

  def default_business?
    id == MINIBAR_ID
  end

  def self.default_business?(business_id)
    business_id == MINIBAR_ID
  end

  def braintree_credentials?
    attrs = %w[ braintree_cse_key_ciphertext braintree_merchant_id_ciphertext
                braintree_private_key_ciphertext braintree_public_key_ciphertext
                braintree_tokenization_key_ciphertext]
    attrs.all? { |attr| attributes[attr].present? }
  end

  private

  def valid_permalinks
    %i[
      fee_supplier_permalink
      product_supplier_permalink
    ].each do |permalink|
      next if public_send(permalink).blank? || Supplier.exists?(permalink: public_send(permalink))

      errors.add(:permalink, 'supplier not found')
    end
  end
end
