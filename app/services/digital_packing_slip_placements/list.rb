module DigitalPackingSlipPlacements
  class List
    include ::ListOrganizer
    has_scope :by_title, as: :title
    has_scope :by_storefront_id, as: :storefront_id
    sortable DigitalPackingSlipPlacement.column_names
    attr_reader :result

    def initialize(params)
      @params = params || {}
    end

    def call
      @result = apply_scopes(DigitalPackingSlipPlacement.all, list_params)
      self
    end
  end
end
