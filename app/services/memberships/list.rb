module Memberships
  class List
    include ::ListOrganizer

    has_scope :by_storefront_id, as: :storefront_id
    has_scope :by_first_name, as: :first_name
    has_scope :by_last_name, as: :last_name
    has_scope :by_user_email, as: :email
    has_scope :by_user_phone, as: :phone

    sortable Membership.column_names

    attr_reader :result

    def call
      @result = apply_scopes(Membership.all, list_params)

      self
    end
  end
end
