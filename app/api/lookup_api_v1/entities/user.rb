class LookupAPIV1::Entities::User < Grape::Entity
  include ActionView::Helpers::DateHelper

  expose :id
  expose :email
  expose :name
  expose :url
  expose :total_orders
  expose :lifetime_value
  expose :last_order_url
  expose :last_order_number
  expose :last_order_supplier
  expose :last_order_date

  private

  def lifetime_value
    object.orders.finished.joins(:order_amount).sum(:taxed_total).to_f.round_at(2)
  end

  def total_orders
    object.orders.finished.count
  end

  def url
    Rails.application.routes.url_helpers.admin_customer_url(object, host: ENV['ASSET_HOST'])
  end

  def last_order_number
    last_order&.number
  end

  def last_order_url
    Rails.application.routes.url_helpers.edit_admin_fulfillment_order_url(last_order.number, host: ENV['ASSET_HOST']) if last_order
  end

  def last_order_supplier
    last_order.shipments.map { |s| s.supplier.name }.join(', ') if last_order
  end

  def last_order_date
    time_ago_in_words(last_order.completed_at) if last_order
  end

  def last_order
    @last_order ||= object.orders.finished.last
  end
end
