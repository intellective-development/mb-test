class Supplier
  module InventoryManagement
    def inventory_updated!
      profile.set_category_metadata
      profile.set_type_metadata

      update_attribute(:last_inventory_update_at, Time.zone.now)
    end

    def inventory_token_activated?
      inventory_token && inventory_token_activated_at
    end

    def activate_inventory_token!
      update(inventory_token_activated_at: Time.zone.now)
    end

    def generate_inventory_token(offset = 0)
      inventory_token = hash_name_id[offset..offset + 5]
      if Supplier.find_by(inventory_token: inventory_token).nil?
        update_attribute(:inventory_token, inventory_token)
      else
        inventory_token = generate_inventory_token(offset + 1)
      end
      inventory_token
    end
  end
end
