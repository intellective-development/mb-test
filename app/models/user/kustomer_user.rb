class User
  include ActionView::Helpers::DateHelper
  module KustomerUser
    extend ActiveSupport::Concern

    def as_kustomer_user
      last_orders = orders.finished.order(completed_at: :desc).limit(5)
      get_order_url = proc { |ord| ord.blank? ? nil : Rails.application.routes.url_helpers.edit_admin_fulfillment_order_url(ord.number, host: (ENV['ASSET_HOST'] || 'https://minibardelivery.com')) }
      {
        name: name,
        emails: [
          {
            type: 'home',
            email: email
          }
        ],
        externalId: id.to_s,
        custom: {
          adminLinkUrl: Rails.application.routes.url_helpers.admin_customer_url(self, host: (ENV['ASSET_HOST'] || 'https://minibardelivery.com')),
          lifetimeValueNum: orders.finished.joins(:order_amount).sum(:taxed_total).round_at(2),
          totalOrdersNum: orders.finished.count,
          lastOrderNumberStr: last_order&.number,
          lastOrderUrl: get_order_url.call(last_order),
          lastOrderDateStr: (time_ago_in_words(last_order.created_at) if last_order),
          lastOrders5thUrl: get_order_url.call(last_orders[4]),
          lastOrders4thUrl: get_order_url.call(last_orders[3]),
          lastOrders3rdUrl: get_order_url.call(last_orders[2]),
          lastOrders2ndUrl: get_order_url.call(last_orders[1]),
          lastOrders1stUrl: get_order_url.call(last_orders[0]),
          vipBool: vip?,
          corporateBool: corporate?
        }
      }
    end
  end
end
