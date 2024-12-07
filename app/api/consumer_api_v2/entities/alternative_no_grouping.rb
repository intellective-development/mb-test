class ConsumerAPIV2::Entities::AlternativeNoGrouping < Grape::Entity
  expose :id do |alternative|
    alternative[:request_id]
  end
  expose :product do |alternative|
    {
      id: alternative[:variant].variant_store_view.variant_id,
      price: alternative[:variant].price.to_f.round_at(2),
      supplier_id: alternative[:variant].supplier_id,
      in_stock: alternative[:variant].count_on_hand
    }
  end
end
