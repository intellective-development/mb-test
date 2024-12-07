# frozen_string_literal: true

module OrderAdjustmentReasons
  # OrderAdjustmentReasons::List
  class List
    include ::ListOrganizer

    has_scope :by_status, as: :status, type: :array, default: %w[true]
    has_scope :by_name, as: :name
    has_scope :adjustment_reasons, as: :adjustment, type: :boolean
    has_scope :cancellation_reasons, as: :cancel, type: :boolean

    sortable %i[name]

    attr_reader :result

    def call
      @result = apply_scopes(OrderAdjustmentReason.all.order(name: :asc), list_params)

      self
    end
  end
end
