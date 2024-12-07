class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    supplier_id = user.supplier_id || 0

    if user.has_role? :supplier
      can %i[read update], Variant, supplier_id: supplier_id
      can %i[read transition update print], Shipment, supplier_id: supplier_id
      can %i[read transition update], Order, shipments: { supplier_id: supplier_id }
      can %i[read transition update print], Shipment, supplier: { delegate_supplier_id: supplier_id }
      can %i[read update comment], Comment, commentable: { shipments: { supplier_id: supplier_id } }, commentable_type: 'Order'
    end

    if user.has_role? :driver
      can %i[read print], Shipment, supplier_id: supplier_id
      can %i[read print], Shipment, supplier: { delegate_supplier_id: supplier_id }
    end

    can :manage, :all if user.has_any_role? :super_admin, :admin
  end
end
