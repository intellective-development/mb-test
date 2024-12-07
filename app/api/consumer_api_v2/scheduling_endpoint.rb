class ConsumerAPIV2::SchedulingEndpoint < BaseAPIV2
  namespace :scheduling do
    desc 'Returns scheduled delivery windows in the server time zone', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      requires :delivery_method_id, type: String, allow_blank: false
    end
    get :windows do
      shipping_method = ShippingMethod.active.find_by(id: params[:delivery_method_id])

      error!('Delivery Method does not exist', 404)            unless shipping_method
      error!('Supplier invalid', 400)                          unless shipping_method.supplier
      error!('Delivery Method does not allow scheduling', 400) unless shipping_method.allows_scheduling

      # TODO: Temporary fix since Biz can throw an error in cases with no hours.
      begin
        error!('Supplier has no available delivery windows', 400) if shipping_method.scheduling_windows.none?
      rescue Biz::Error::Configuration => e
        error!('Supplier has no available delivery windows', 400)
      end

      present shipping_method.scheduling_windows, with: ConsumerAPIV2::Entities::SchedulingCalendar
    end
  end
end
