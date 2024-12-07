class ProductUpdateJob
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: :web_product_updates

  def perform_with_error_handling(payload)
    payload_struct = JiffyBag.decode_as_struct(payload)
    changeset = ProductGroupingChangeset.find_or_initialize_by(product_grouping_id: payload_struct.product_grouping_id)

    case payload_struct.state
    when 'submitted'
      changeset.update!(
        changeset: payload_struct.changeset,
        account_id: payload_struct.account_id,
        duplicate_id: payload_struct.respond_to?(:duplicate_id) && payload_struct.duplicate_id,
        message: payload_struct.respond_to?(:message) && payload_struct.message
      )
    when 'cancelled'
      changeset.trigger!(:cancel)
    end
  end
end
