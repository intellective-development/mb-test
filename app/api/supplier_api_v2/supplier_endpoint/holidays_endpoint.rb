# frozen_string_literal: true

class SupplierAPIV2
  class SupplierEndpoint
    # Supplier Holidays endpoint
    class HolidaysEndpoint < BaseAPIV2
      helpers Shared::Helpers::Supplier::HolidayHelper, Shared::Helpers::Supplier::HolidayParamHelper

      before do
        authorize!
      end

      namespace :supplier do
        resource :holidays do
          params do
            use :holiday_params
          end

          desc 'Create holidays for main and delegate suppliers.'
          post do
            result = Suppliers::Holidays::BulkCreate.new(params: holiday_params).call

            error!(result.error, 422) unless result.success?

            status 201
            present result.holidays, with: SupplierAPIV2::Entities::Supplier::Holiday
          end

          desc "Get supplier's holidays"
          get do
            @holidays = current_supplier.holidays.upcoming_all.distinct.sort { |h1, h2| h1.as_date <=> h2.as_date }

            status 200
            present @holidays, with: SupplierAPIV2::Entities::Supplier::Holiday
          end

          route_param :id do
            before do
              set_holiday
            end

            desc 'Delete a given holiday'
            delete do
              if @holiday.destroy
                body false
              else
                error!(@holiday.errors.full_messages.to_sentence, 422)
              end
            end
          end
        end
      end

      helpers do
        def set_holiday
          @holiday = current_supplier.holidays.distinct.find_by(id: params[:id])

          error!('Holiday not found', 404) if @holiday.nil?
        end

        def holiday_params
          data = permitted_supplier_holiday_params(params)
          data[:user_id] = current_user.id
          data[:shipping_types] = ShippingMethod::IN_STORE_SHIPPING_TYPES
          data[:suppliers] = Supplier.where(id: current_supplier_ids)

          data
        end
      end
    end
  end
end
