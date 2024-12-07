class Order::AddMembership
  attr_reader :order, :error

  def initialize(order:)
    @order = order
  end

  def call
    if order.membership_plan_id.present?
      add_new_membership_to_order
    else
      add_user_membership_to_order_if_exist
    end

    self
  end

  def success?
    @success
  end

  private

  def add_new_membership_to_order
    return user_already_has_membership_error if user_membership.present?
    return membership_plan_is_not_active unless @order.membership_plan.active?

    result = ::Memberships::Create.call_from_order!(@order)
    return unless result.success?

    update_order_membership(result.membership)
  end

  def add_user_membership_to_order_if_exist
    update_order_membership(user_membership)
    @order.save_order_amount(skip_coupon_creation: true) if order.membership_id != user_membership&.id
  end

  def update_order_membership(membership)
    @success = @order.update(membership: membership)
  end

  def user_membership
    return @user_membership if defined?(@user_membership)

    @user_membership = Membership.active.find_by(user_id: order.user_id, storefront_id: order.storefront_id)
  end

  def user_already_has_membership_error
    @error = 'User already has a membership.'
    @success = false
  end

  def membership_plan_is_not_active
    @error = 'Membership is not active.'
    @success = false
  end
end
