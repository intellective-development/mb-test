class SupplierAPIV2::InventoryEndpoint < BaseAPIV2
  namespace :add_top_beers do
    desc "Add beer products to supplier's inventory from the template store (typically top saling beers)."
    put do
      InventoryInitializationService.add_beers(current_supplier)
    end
  end
end
