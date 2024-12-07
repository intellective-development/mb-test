module Businesses
  class List
    include ::ListOrganizer

    has_scope :by_name, as: :name

    sortable FulfillmentService.column_names

    attr_reader :result

    def call
      @result = apply_scopes(Business.all, list_params)

      self
    end
  end
end
