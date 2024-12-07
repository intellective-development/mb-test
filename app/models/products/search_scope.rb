# frozen_string_literal: true

module Products
  module SearchScope # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern

    included do
      cattr_accessor(:search_scopes) { [] }

      search_scopes << :with_stock
    end

    module ClassMethods # rubocop:todo Style/Documentation
      def with_stock
        ids = Variant.available.pluck(:product_id)
        where("#{Product.quoted_table_name}.id IN (?)", ids)
      end
    end
  end
end
