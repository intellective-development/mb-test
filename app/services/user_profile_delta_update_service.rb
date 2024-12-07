class UserProfileDeltaUpdateService
  # This class is responsible for updating a users profile following an order. Since we want to keep
  # this as efficient as possible we are only updating what we can without heavy database queries.
  # This serves as an interim means of updating, then we can do a full refresh if necessary in-between.

  def initialize(_user_id, order_id)
    @order    = Order.finished.includes(:product_size_groupings, :suppliers, :order_items, user: [:profile]).find(order_id)
    @user     = @order.user
    @profile  = @order.user.profile
  end

  def call
    @user.profile ? perform_delta_update : UserProfileUpdateWorker.perform_async(@user.id)
  end

  private

  def perform_delta_update
    @profile.max_price = order_items.first.price.to_f.round_at(2) if order_items.last.price > @profile.max_price
    @profile.min_price = order_items.first.price.to_f.round_at(2) if order_items.first.price < @profile.min_price
    @profile.ordered_subtypes   = (@profile.ordered_subtypes + product_groupings.pluck(:hierarchy_subtype_id)).uniq.compact
    @profile.ordered_types      = (@profile.ordered_types + product_groupings.pluck(:hierarchy_type_id)).uniq.compact
    @profile.ordered_categories = (@profile.ordered_categories + product_groupings.pluck(:hierarchy_category_id)).uniq.compact
    @profile.recently_ordered_types      = (@profile.recently_ordered_types + product_groupings.pluck(:hierarchy_type_id)).uniq.compact
    @profile.recently_ordered_subtypes   = (@profile.recently_ordered_subtypes + product_groupings.pluck(:hierarchy_subtype_id)).uniq.compact
    @profile.recently_ordered_categories = (@profile.recently_ordered_categories + product_groupings.pluck(:hierarchy_category_id)).uniq.compact
    @profile.last_region = region_id
    @profile.order_regions = (@profile.order_regions << region_id).uniq
    @profile.last_delta_update = Time.zone.now
    @profile.save
  end

  def region_id
    @region_id = @order.suppliers.first&.region_id
  end

  def order_items
    @order_items ||= @order.order_items.order(:price)
  end

  def product_groupings
    @product_groupings ||= @order.product_size_groupings
  end
end
