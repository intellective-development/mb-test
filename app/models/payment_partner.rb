# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_partners
#
#  id                           :integer          not null, primary key
#  name                         :string
#  api_client_id_ciphertext     :text
#  api_client_secret_ciphertext :text
#  api_salt_secret_ciphertext   :text
#  hmac_secret_ciphertext       :text
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
class PaymentPartner < ActiveRecord::Base
  ENCRYPTED_ATTRS = %i[api_client_id api_client_secret api_salt_secret hmac_secret].freeze
  CHARS_LENGTH_ALPHANUMERIC_REGEX = /\A[[a-f0-9]+\Z]{32}$/i.freeze

  validates :api_client_id, :api_client_secret, :api_salt_secret,
            :hmac_secret, :name, presence: true
  validates :name, uniqueness: true
  validates :api_client_id, :api_client_secret, :api_salt_secret, :hmac_secret, format: { with: CHARS_LENGTH_ALPHANUMERIC_REGEX, multiline: true }

  encrypts :api_client_id, :api_client_secret, :api_salt_secret, :hmac_secret

  after_initialize :generate_keys, if: :new_record?

  private

  def generate_keys
    keys = ENCRYPTED_ATTRS.index_with { |_key| SecureRandom.hex }
    assign_attributes(keys)
  end
end
