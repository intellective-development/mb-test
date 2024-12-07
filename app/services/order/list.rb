class Order::List
  include ::ListOrganizer

  has_scope :by_membership_id, as: :membership_id

  sortable Order.column_names

  attr_reader :result

  def call
    @result = apply_scopes(Order.all, list_params)

    self
  end
end
