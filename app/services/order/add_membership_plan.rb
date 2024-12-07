class Order::AddMembershipPlan
  attr_reader :order, :membership_plan_id

  def initialize(order:, membership_plan_id:)
    @order = order
    @membership_plan_id = membership_plan_id
  end

  def call
    return self if membership_plan.blank? || active_membership?

    @success = Order.transaction do
      order.update!(membership_plan: membership_plan)

      raise ActiveRecord::Rollback unless order.recalculate_and_apply_taxes

      true
    rescue ActiveRecord::RecordInvalid
      raise ActiveRecord::Rollback
    end
    self
  end

  def success?
    @success
  end

  def membership_plan
    return @membership_plan if defined?(@membership_plan)

    @membership_plan = MembershipPlan.active.find_by(id: membership_plan_id, storefront_id: order.storefront_id)
  end

  def active_membership?
    Membership.where(user_id: order.user_id, storefront_id: order.storefront_id).active.exists?
  end
end
