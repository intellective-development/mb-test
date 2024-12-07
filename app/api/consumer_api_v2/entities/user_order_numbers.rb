# frozen_string_literal: true

# User order numbers entity
class ConsumerAPIV2::Entities::UserOrderNumbers < Grape::Entity
  expose :id
  expose :email
  expose :first_name
  expose :last_name
  expose :order_numbers

  private

  def order_numbers
    object.orders.finished.pluck(:number)
  end
end
