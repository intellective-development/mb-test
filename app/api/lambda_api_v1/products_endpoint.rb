class LambdaAPIV1::ProductsEndpoint < BaseAPIV1
  namespace :products do
    namespace :bulk_update do
      params do
        requires :supplier_id, type: Integer
        requires :file_url, type: String
        requires :external_id, type: String
        requires :options, type: Hash do
          requires :remove_items_not_present, type: Boolean
          requires :replace_inventory, type: Boolean
          requires :update_products, type: Boolean
        end
      end
      post :update do
        job_params =
          {
            'supplier_id' => params[:supplier_id],
            'file_url' => params[:file_url],
            'options' => params[:options],
            'external_id' => params[:external_id]
          }
        InventoryUpdateJob.perform_async(job_params)
      end
    end
  end
end
