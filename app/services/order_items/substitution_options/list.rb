# frozen_string_literal: true

module OrderItems
  module SubstitutionOptions
    # OrderItems::SubstitutionOptions::List
    class List
      attr_accessor :substitution_options

      def initialize(order_item:)
        @order_item = order_item
        @substitution_options = []
      end

      def call
        @substitution_options = find_substitution_options

        self
      end

      private

      def find_substitution_options
        substitution_options = Variant.joins(%i[product_size_grouping supplier inventory])
                                      .merge(ProductSizeGrouping.where('product_groupings.product_type_id IN (?)', product_type_ids))
                                      .where(supplier_id: supplier.id)
                                      .limit(20)

        selected_substitution_options(substitution_options)
      end

      def product_type_ids
        @product_type_ids ||= variant&.product&.product_type&.type_tree_ordered&.pluck(:id) || []
      end

      def supplier
        @supplier ||= @order_item.shipment.supplier
      end

      def selected_substitution_options(substitution_options)
        product_type_ids.flat_map { |pt_id| substitution_options.select { |s| s.product_size_grouping.product_type.id == pt_id } }
      end

      def variant
        @variant ||= Variant.find_by(sku: @order_item.variant.sku)
      end
    end
  end
end
