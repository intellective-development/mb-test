class YotpoWebhooks < BaseAPI
  format :json

  helpers do
    def save_log(params)
      log_data = { params: params }
      YotpoWebhookLog.create(log_data)
    end

    def schedule_next_product_batch
      YotpoProductFeedWorker.perform_async
    end
  end

  resource :mass_products do
    desc 'Creates new mass product creation log and schedules next batch'
    params do
    end
    post do
      save_log(params)
      schedule_next_product_batch

      { status: 'success' }
    end
  end

  resource :update_mass_products do
    desc 'Update mass product creation log and schedules next batch'
    params do
      optional :batch_id, type: String, allow_blank: true, desc: 'The batch id for the mass update product'
      optional :page, type: Integer, allow_blank: true, desc: 'Specifies the page to be processed'
    end
    post do
      YotpoUpdateMassProductFeedWorker.perform_async(params)

      { status: 'success' }
    end
  end
end
