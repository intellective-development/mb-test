# TODO: This is horrible! We should turn this into a database view in order to avoid the ActiveRecord fun and games!

module MinibarReports
  class DailyStatus
    def initialize
      starts_at = Date.yesterday.beginning_of_day
      ends_at   = Date.yesterday.end_of_day

      @orders = Order.finished
                     .where('orders.created_at > ?', starts_at)
                     .where('orders.created_at < ?', ends_at)
                     .not_in_state('verifying')
                     .includes([order_items: [:tax_rate, { variant: %i[supplier product] }], user: [:orders]])
      @cancelled_orders = @orders.where(state: 'canceled')

      @suppliers = @orders.flat_map { |o| o.order_suppliers.map(&:name) }
      @supplier_values_with_counts = supplier_values_with_counts

      @product_type_count = product_root_type_count
      @product_type_value = product_root_type_value

      @platform_count = platform_count
      @platform_value = platform_value

      @users = User.where('created_at > ?', starts_at).count
    end

    def hunger_games
      @hunger_games = Count.like('hunger_games').where(date: Date.yesterday).order(value: :desc)
    end

    def supplier_graph_url
      chart_data    = normalize(@supplier_values_with_counts.map { |s| s[1][:count] }).join(',')
      chart_labels  = @supplier_values_with_counts.map { |s| s[0].parameterize }.join('|')
      resolution    = '800x375'
      chart_color   = 'CC0000'
      "http://chart.apis.google.com/chart?cht=p&chs=#{resolution}&chd=t:#{chart_data}&chl=#{chart_labels}&chco=#{chart_color}"
    end

    def product_type_graph_url
      chart_data    = normalize(@product_type_count.map { |s| s[1] }).join(',')
      chart_labels  = @product_type_count.map { |s| s[0] }.join('|')
      chart_color = '0099CC'
      "http://chart.apis.google.com/chart?cht=p&chs=500x350&chd=t:#{chart_data}&chl=#{chart_labels}&chco=#{chart_color}"
    end

    def product_type_value_graph_url
      chart_data    = normalize(@product_type_value.map { |s| s[1] }).join(',')
      chart_labels  = @product_type_value.map { |s| s[0] }.join('|')
      chart_color = '669900'
      "http://chart.apis.google.com/chart?cht=p&chs=500x350&chd=t:#{chart_data}&chl=#{chart_labels}&chco=#{chart_color}"
    end

    def platform_count_graph_url
      chart_data    = normalize(@platform_count.map { |s| s[1] }).join(',')
      chart_labels  = @platform_count.map { |s| s[0] }.join('|')
      chart_color = platform_colors(@platform_count).join('|')
      "http://chart.apis.google.com/chart?cht=p&chs=500x350&chd=t:#{chart_data}&chl=#{chart_labels}&chco=#{chart_color}"
    end

    def platform_value_graph_url
      chart_data    = normalize(@platform_value.map { |s| s[1] }).join(',') # /1000 to account for error in api. normalize?
      chart_labels  = @platform_value.map { |s| s[0] }.join('|')
      chart_color = platform_colors(@platform_value).join('|')
      "http://chart.apis.google.com/chart?cht=p&chs=500x350&chd=t:#{chart_data}&chl=#{chart_labels}&chco=#{chart_color}"
    end

    def normalize(collection)
      total = collection.sum
      collection.map { |c| c.to_f / total } || []
    end

    def product_type_count
      product_types = @orders.flat_map do |o|
        o.order_items.map do |i|
          next unless i.variant.product_type

          i.variant.product_type.name_list.join(' &#8594; ')
        end
      end.compact
      calculate_count(product_types)
    end

    def product_root_type_count
      product_roots = @orders.flat_map do |o|
        o.order_items.map do |i|
          category = i.variant.product.hierarchy_category
          category ? category.name : 'Unknown'
        end
      end
      calculate_count(product_roots)
    end

    def product_root_type_value
      product_roots = @orders.flat_map do |o|
        o.order_items.map do |i|
          category = i.variant.product.hierarchy_category
          label = category ? category.name : 'Unknown'
          [label, i.total]
        end
      end

      calculate_sum(product_roots)
    end

    def supplier_values_with_counts
      suppliers = @orders.flat_map { |o| o.shipments.map { |s| [s.supplier.name, s.total_amount] } }
      calculate_sum_with_count(suppliers)
    end

    def platform_count
      platforms = @orders.map(&:platform)
      calculate_count(platforms)
    end

    def platform_value
      platforms = @orders.flat_map do |o|
        o.order_items.map do |i|
          [o.platform, i.total]
        end
      end

      calculate_sum(platforms)
    end

    def platform_colors(platforms)
      colors =  {
        iphone: '33B5E5', iphone_web: '0099CC',
        ipad: 'E533B5', ipad_web: 'CC0099',
        android: '99CC00', android_web: '669900',
        web: 'FF4444'
      }
      platforms.map { |s| colors[s[0].to_sym] ||= 'C0C0C0' }
    end

    def total_products
      Product.count - Product.inactive.count
    end

    def total_unidentified_products
      Product.pending.with_stock.count
    end

    def order_item_count
      order_items = @orders.flat_map { |o| o.order_items.map { |i| i.variant.product_name } }
      calculate_count(order_items)
    end

    def new_user_count
      @users
    end

    attr_reader :supplier_count, :orders

    def top_supplier
      top = @supplier_values_with_counts.first
      if top.present?
        { name: top[0], count: top[1][:count], value: top[1][:value] }
      else
        { name: '', count: '', value: '' }
      end
    end

    def average_order_value
      total_amount / total_orders
    rescue StandardError
      0
    end

    def total_repeat_orders
      @orders.to_a.sum { |o| o.user.orders.finished.length > 1 ? 1 : 0 }
    end

    def total_amount
      @orders.map(&:taxed_total).sum(&:to_f) + @orders.map(&:coupon_amount).sum(&:to_f)
    end

    def total_cancelled_amount
      @cancelled_total = @orders.where(state: 'canceled').to_a.map(&:taxed_total).compact.sum
    end

    def total_cancelled_orders
      @cancelled_orders.size
    end

    def total_orders
      @orders.size
    end

    private

    def calculate_count(collection) # counts appearances of each
      return [] if collection.nil?

      count = Hash.new(0)
      collection.each { |v| count.store(v, count[v] + 1) }
      count = count.sort_by { |i| i[1] }.reverse
    end

    def calculate_sum(paired_collection) # sums the value, taking first el of subarray as key, second as val
      return [] if paired_collection.nil?

      count = Hash.new(0)
      paired_collection.each do |a|
        k = a[0]
        val = count[k] + a[1]
        count.store(k, val)
      end
      count = count.sort_by { |i| i[1] }.reverse
    end

    def calculate_sum_with_count(paired_collection) # sums the value, taking first el of subarray as key, second as val
      return [] if paired_collection.nil?

      count = {}
      paired_collection.each do |a|
        k = a[0]
        count[k] ||= { count: 0, value: 0 }
        count[k][:value] += a[1]
        count[k][:count] += 1
      end
      count = count.sort_by { |i| [i[1][:count], i[1][:value]] }.reverse
    end
  end
end
