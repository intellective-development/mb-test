module ProductRoutings
  class List
    include ::ListOrganizer

    has_scope :by_active, as: :active, type: :array
    has_scope :by_name, as: :name

    sortable ProductRouting.column_names

    attr_reader :result

    def call
      @result = apply_scopes(ProductRouting.all, list_params)

      self
    end
  end
end
