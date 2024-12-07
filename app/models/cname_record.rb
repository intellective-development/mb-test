# frozen_string_literal: true

# == Schema Information
#
# Table name: cname_records
#
#  id                 :bigint(8)        not null, primary key
#  domain             :string
#  status             :integer          default("pending"), not null
#  certificate_arn    :string
#  api_gateway_domain :string
#  storefront_id      :bigint(8)        not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_cname_records_on_domain_and_storefront_id  (domain,storefront_id) UNIQUE
#  index_cname_records_on_storefront_id             (storefront_id)
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#
class CnameRecord < ApplicationRecord
  INTERNAL_SUBDOMAINS = [
    'liquidcheckout.com',
    'reservebar.com'
  ].freeze
  SSL_ISSUING_WAIT_TIME = 6.hours.freeze

  belongs_to :storefront

  enum status: {
    pending: 0,
    creating_ssl_certificate: 1,
    ssl_certificate_created: 2,
    creating_custom_domain: 3,
    custom_domain_created: 4,
    creating_cname_record: 5,
    cname_record_created: 6
  }

  validates :domain, uniqueness: { scope: :storefront_id }
  validates :domain, presence: true
  validate :storefront_hostname
  validate :staging_domain

  def zone
    return nil unless internal?

    INTERNAL_SUBDOMAINS.find { |subdomain| domain.match?(".#{subdomain}") }
  end

  def internal?
    INTERNAL_SUBDOMAINS.any? { |subdomain| domain&.match?(".#{subdomain}") }
  end

  def update_disabled?
    persisted? && !cname_record_created?
  end

  private

  def storefront_hostname
    errors.add(:domain, 'is not unique') if Storefront.exists?(hostname: domain)
  end

  def staging_domain
    invalid_domain = internal? && !Rails.env.production? && !domain.match?('-staging')
    errors.add(:domain, "should contain '-staging' when env is staging") if invalid_domain
  end
end
