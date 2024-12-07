class PackagingAPIV1::OrdersEndpoint < PackagingAPIV1
  namespace :orders do
    route_param :number do
      desc 'Returns an order by given order number and purchaser/gift_recipient email or a hash'
      params do
        optional :email, type: String, desc: 'Email', allow_blank: false
        optional :hash, type: String, allow_blank: false

        exactly_one_of :email, :hash
      end

      get do
        @order = Order.find_by(number: params[:number].strip)

        error!('Order not found', 404) unless order_checks_passed?(@order, params[:email], params[:hash])

        status 200
        present @order, with: PackagingAPIV1::Entities::Order
      end
    end
  end

  helpers do
    def order_checks_passed?(order, email, hash)
      order.present? && (order_hash_valid?(order, hash) || email_param_matches_order_purchaser_or_gift_recipient_email?(order, email))
    end

    def order_hash_valid?(order, hash)
      return false if hash.blank?

      hasher = Order::Hasher.new(order: order)
      hasher.hash_valid?(hash)
    end

    def email_param_matches_order_purchaser_or_gift_recipient_email?(order, email)
      return false if email.blank?

      [order.user.email.downcase, order.gift_detail&.recipient_email&.downcase].include?(email.strip.downcase)
    end
  end
end
