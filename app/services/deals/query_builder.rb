module Deals
  class QueryBuilder
    def initialize(params, **options)
      @params = params
      @base_scope = options[:scope] || Deal.unscoped
    end

    def call
      combined_scopes_or_none.available_and_active
    end

    def combined_scopes_or_none
      combined_scopes == @base_scope ? @base_scope.none : combined_scopes
    end

    def combined_scopes
      combined = []
      @params.compact.each do |key, values|
        if values.is_a?(ActiveRecord::Relation)
          combined.push(values)
        elsif KEY_MAPPINGS[key]
          combined.push(Deal.for_type_and_ids(KEY_MAPPINGS[key], values))
        end
      end
      combined.inject { |scopes, condition| scopes.or(condition) }
    end

    KEY_MAPPINGS = ActiveSupport::HashWithIndifferentAccess.new(
      {
        regions: 'Region',
        states: 'State',
        suppliers: 'Supplier',
        brands: 'Brand',
        product_types: 'ProductType',
        product_groupings: 'ProductSizeGrouping',
        products: nil
      }
    )
  end
end
