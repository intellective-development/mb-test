class AdminNotifier < BaseNotifier
  def daily_status
    Rails.logger.info('Started daily status report')
    daily_status = MinibarReports::DailyStatus.new

    @hunger_games = daily_status.hunger_games

    @order_count        = daily_status.total_orders
    @cancelled_count    = daily_status.total_cancelled_orders
    @total              = daily_status.total_amount
    @cancelled_total    = daily_status.total_cancelled_amount
    @aov                = daily_status.average_order_value
    @new_users          = daily_status.new_user_count
    @repeat_orders      = daily_status.total_repeat_orders
    @top_store          = daily_status.top_supplier
    @order_item_count   = daily_status.order_item_count

    @store_data         = daily_status.supplier_values_with_counts
    @store_data_first   = @store_data.slice(0, (@store_data.length + 1) / 2)
    @store_data_second  = @store_data.slice((@store_data.length + 1) / 2, @store_data.length)
    @product_count      = daily_status.total_products
    @product_type_count = daily_status.product_type_count
    @product_root_type_count  = daily_status.product_root_type_count
    @product_root_type_value  = daily_status.product_root_type_value
    @platform_count     = daily_status.platform_count
    @platform_value     = daily_status.platform_value

    @supplier_graph_url           = daily_status.supplier_graph_url
    @product_type_graph_url       = daily_status.product_type_graph_url
    @product_type_value_graph_url = daily_status.product_type_value_graph_url
    @platform_count_graph_url     = daily_status.platform_count_graph_url
    @platform_value_graph_url     = daily_status.platform_value_graph_url
    @product_unrecognized_count = daily_status.total_unidentified_products

    mail(to: 'dailystatus@minibardelivery.com', subject: format_subject("[Minibar] Daily Status for #{Date.today.strftime('%D')}")) do |format|
      format.html { render layout: 'email_ink' }
    end
    Rails.logger.info('Mails sent  ')
  end
end
