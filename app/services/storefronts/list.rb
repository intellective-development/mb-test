module Storefronts
  class List
    include ::ListOrganizer

    has_scope :by_name,   as: :name
    has_scope :by_status, as: :status, type: :array

    sortable Storefront.column_names

    attr_reader :result

    def call
      @result = apply_scopes(Storefront.all, list_params)

      self
    end
  end
end
