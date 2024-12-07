class Account::OrdersController < Account::BaseController
  layout 'minibar'

  def index
    @orders = current_user.finished_orders
                          .completed_desc
                          .page(params[:page])
                          .per(8)
  end

  def show
    @order = current_user.finished_orders
                         .includes([{ order_items: { variant: :product } }])
                         .find_by(number: params[:id])
  end

  def pdf
    @order ||= current_user.finished_orders
                           .includes([{ order_items: [{ variant: :product }, :order, :supplier, :product, :product_type, :tax_rate] }, { shipments: :order_items }, { order_suppliers: :supplier_type }])
                           .find(params[:id])
    render layout: false
  end
end
