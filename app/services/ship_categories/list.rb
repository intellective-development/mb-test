module ShipCategories
  class List
    include ::ListOrganizer

    has_scope :by_name, as: :name

    sortable ShipCategory.column_names

    attr_reader :result

    def call
      @result = apply_scopes(ShipCategory.all, list_params)

      self
    end
  end
end
