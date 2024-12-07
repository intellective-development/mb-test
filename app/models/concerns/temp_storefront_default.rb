# TODO: this is a temporary hack for transitional period. To keep existing code working we automatically assign
# all new records to Minibar storefront, if no storefront_id is specified on creation. We should remove this
# logic later

module TempStorefrontDefault
  extend ActiveSupport::Concern

  include CriticalWarning

  included do
    before_validation :set_default_storefront, on: :create
  end

  private

  def set_default_storefront
    if storefront_id.nil?
      critical_warning("Tried to create #{self.class.name} record without storefront. Fallback to Minibar.")
      self.storefront_id = Storefront::MINIBAR_ID
    end
  end
end
