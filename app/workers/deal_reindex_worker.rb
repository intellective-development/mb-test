class DealReindexWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(subject_id, subject_type, deal_type, persisted)
    product_size_grouping_types = ActiveSupport::HashWithIndifferentAccess.new(
      {
        'Brand': 'brand_id',
        'ProductType': 'product_type_id',
        'ProductSizeGrouping': 'id'
      }
    )
    if subject_type == 'Supplier'
      variants = Variant.where(supplier_id: subject_id)
      if deal_type == 'VolumeDiscount'
        # set case_eligible depending of deal is created or destroyed
        variants.update_all(case_eligible: persisted)
      end
      variants.find_each do |variant|
        variant.reindex_async
        variant.product&.reindex_async
        variant.product&.product_size_grouping&.reindex_async
      end
    elsif product_size_grouping_types.key?(subject_type)
      ProductSizeGrouping.where(product_size_grouping_types[subject_type] => subject_id).find_each(&:reindex_async)
    end
  end
end
