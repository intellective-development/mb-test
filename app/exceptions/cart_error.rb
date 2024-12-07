class CartError < StandardError
  class VariantNotFound < CartError; end
end
