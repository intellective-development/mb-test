module StorefrontFonts
  class List
    include ::ListOrganizer
    has_scope :by_name, as: :name
    has_scope :by_storefront_id, as: :storefront_id
    sortable StorefrontFont.column_names
    attr_reader :result

    def initialize(params)
      @params = params || {}
    end

    def call
      @result = apply_scopes(StorefrontFont.all, list_params)
      self
    end
  end
end
