# frozen_string_literal: true

class SupplierAPIV2
  module Entities
    class Supplier
      # Supplier Holiday entity
      class Holiday < Grape::Entity
        expose :id
        expose :date
      end
    end
  end
end
