class ConsumerAPIV2::Entities::OrderStatusAction < Grape::Entity
  expose :label do |object|
    I18n.t("order.status_action.#{object.shipping_method.shipping_type}")
  end
  expose :url do |object|
    # TODO: If these are static, consider storing these on the shipment
    # metadata when we have enough information to do so. This could also gate
    # the exposure of the status action itself.
    OrderStatusActionService.new(object).generate_url
  end
end
