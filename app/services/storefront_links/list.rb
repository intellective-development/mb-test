module StorefrontLinks
  class List
    include ::ListOrganizer
    has_scope :by_name, as: :name
    sortable StorefrontLink.column_names
    attr_reader :result, :storefront_id

    def initialize(params)
      @params = params || {}
      @storefront_id = params['storefront_id']
    end

    def call
      @result = apply_scopes(StorefrontLink.where(storefront_id: storefront_id).all, list_params)

      self
    end
  end
end
