# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::Supplier
    class Supplier < Grape::Entity
      expose :display_name, as: :name
      expose :id
      expose :permalink
      expose :logo_url do |supplier|
        supplier.get_supplier_logo&.logo&.image&.url(:original)
      end
    end
  end
end
