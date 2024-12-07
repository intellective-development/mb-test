module PreSales
  class List
    include ::ListOrganizer

    has_scope :by_status, as: :status, type: :array
    has_scope :by_name, as: :name

    sortable PreSale.column_names

    attr_reader :result

    def call
      @result = apply_scopes(PreSale.includes(:product_order_limit, product: [:product_type]), list_params)

      self
    end

    def pagination_per_page
      5
    end
  end
end
