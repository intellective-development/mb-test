module Order::MetadataField
  extend ActiveSupport::Concern

  # array of allowed keys
  METADATA_ALLOWED_ATTRIBUTES = %w[partner_order_id partner_id partner_order_date].freeze

  included do
    before_validation :clean_up_metadata
  end

  def partner_order_id
    metadata['partner_order_id'] unless metadata.nil?
  end

  private

  def clean_up_metadata
    # this can be better modeled with rails 6+ with ActiveRecord::Type::Json
    return if metadata.blank?

    self.metadata = metadata.stringify_keys.slice(*METADATA_ALLOWED_ATTRIBUTES)
  end
end
