# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Dashboard
  module Integration
    module ThreeJMS
      module Webhooks
        # ThreeJMS OrderUpdateWebhookHelpers
        module OrderUpdateWebhookHelpers
          extend Grape::API::Helpers

          params :order_update_params do
            optional :order_id, type: String
            optional :linked_orders, type: Array do
              optional :order_id, type: String
            end
            optional :retailer, type: String
            requires :retailer_order_id, type: String
            requires :status, type: String
            optional :substatus, type: String
            optional :refund, type: Boolean
            optional :items, type: Array do
              optional :id, type: Integer
              optional :name, type: String
              optional :quantity, type: Integer
              optional :sku, type: String
            end
            optional :shipments, type: Array do
              optional :tracking_number, type: String
              optional :tracking_url, type: String
              optional :items, type: Array do
                optional :id, type: Integer
                optional :name, type: String
                optional :quantity, type: Integer
                optional :sku, type: String
              end
            end
            optional :shipped_date, type: DateTime
          end

          params :internal_note_params do
            requires :order, type: String
            requires :description, type: String
            optional :user, type: String
          end

          ORDER_STATUSES = {
            action_req: 'action_req',
            created: 'new_order',
            confirmed: 'confirmed',
            printed: 'printed',
            packed: 'packed',
            pre_transit: 'pre_transit',
            in_transit: 'in_transit',
            completed: 'completed',
            canceled: 'canceled'
          }.freeze

          EXCEPTION_SUB_STATUSES = [
            'Breakage',
            'Items We Dont Carry',
            'Lost in Transit by carrier',
            'No Coverage',
            'Other reason',
            'Returned'
          ].freeze

          DO_NOT_CANCEL_SUB_STATUSES = %w[
            Breakage
            Returned
          ].freeze

          ASANA_TASK_STATUSES = [
            'Breakage',
            'Lost in Transit by carrier'
          ].freeze

          def authenticate!
            request_token = headers['Marketplace-Key'] || headers['marketplace-key'] || headers['MARKETPLACE-KEY']
            valid_token = ENV['THREE_JMS_WEBHOOK_TOKEN'] || 'someth1ng-w3ird-to-n0t-be-m4tch3d'

            error!('Missing or invalid API Token', 401) unless request_token == valid_token
          end

          def split_order?
            params[:retailer_order_id] =~ /-P\d$/ # Split order
          end

          def should_cancel_shipment?(shipment, linked_orders)
            ((linked_orders.is_a?(Array) && (linked_orders.size + 1) == shipment.packages.size) || linked_orders.nil?) &&
              shipment.packages.joins(:package_custom_detail).where("package_custom_details.status != 'canceled'").empty?
          end

          def should_deliver_shipment?(shipment, linked_orders)
            ((linked_orders.is_a?(Array) && (linked_orders.size + 1) == shipment.packages.size) || linked_orders.nil?) &&
              shipment.packages.joins(:package_custom_detail).where("package_custom_details.status != 'completed'").empty?
          end

          def get_package_by_reference(shipment, reference)
            shipment.packages.select { |p| p.package_custom_detail&.package_external_id == reference }.first
          end

          def hold_order(shipment)
            ds = Dashboard::Integration::ThreeJMSDashboard.new shipment.effective_supplier
            ds.hold_order(shipment)
          end

          def add_do_not_ship_yet_note(shipment)
            ds = Dashboard::Integration::ThreeJMSDashboard.new shipment.effective_supplier
            ds.send_comment(shipment, Comment.new(note: 'Do Not Ship Yet. Please, wait for a confirmation.'))
          end

          def create_package(shipment, params)
            reference = params[:retailer_order_id]

            package = get_package_by_reference(shipment, reference)

            Rails.logger.warn("[3JMS Webhook] Package has already been created to shipment #{shipment.id}") if package.present?

            ex_shipment = params[:shipments][0]
            tracking_url = ex_shipment[:tracking_url]
            tracking_number = ex_shipment[:tracking_number]
            reference = params[:retailer_order_id]

            if tracking_url || tracking_number
              package = shipment.packages.create(tracking_number: tracking_number)
              package_content_text = ex_shipment[:items].map { |i| "#{i[:quantity]} - #{i[:name]}" }.join(', ')
              Package::CustomDetail.create!(
                package_external_id: reference,
                package_description: "Package content: #{package_content_text}",
                tracking_url: tracking_url,
                package: package,
                status: params[:status]
              )
              AfterShip::CreateTrackingService.new(package, true).call
              Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, "<- Package #{reference} has been created with status #{status}#{params[:substatus].nil? ? '' : " and substatus #{params[:substatus]}"}")
            else
              Rails.logger.error("[3JMS Webhook] No tracking details provided for Shipment #{shipment.id}: #{params}")
            end
          rescue StandardError => e
            Rails.logger.error("#{e.message}\n#{e.backtrace&.join("\n")}")
            raise e
          end

          def update_package(shipment, params)
            package_external_id = params[:retailer_order_id]
            status = params[:status]

            package = get_package_by_reference(shipment, package_external_id)
            unless package.nil?
              package.package_custom_detail.status = status
              package.package_custom_detail.save

              Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, "<- Package #{package_external_id} has changed status to #{status}, substatus #{params[:substatus]}")
            end

            case status
            when ORDER_STATUSES[:canceled]
              if DO_NOT_CANCEL_SUB_STATUSES.include?(params[:substatus]) || params[:refund] == false
                Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, "<- Shipment exception: #{params[:substatus]}")
                return
              end
              if should_cancel_shipment?(shipment, params[:linked_orders])
                raise StandardError, "Invalid state transition from #{shipment.state} to canceled" unless shipment.can_transition_to?(:canceled)

                Dashboard::Integration::ThreeJMSDashboard.mark_shipment_canceled(shipment.id, shipment.supplier_id)
                shipment.cancel!
                Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, "<- Shipment canceled. #{params[:substatus]}")

              end
            when ORDER_STATUSES[:completed]
              if should_deliver_shipment?(shipment, params[:linked_orders])
                raise StandardError, "Invalid state transition from #{shipment.state} to delivered" unless shipment.can_transition_to?(:delivered)

                shipment.deliver!
                Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, '<- Shipment delivered')

              end
            end
          end

          def create_package_if_not_exists(shipment, data)
            return unless data[:shipments].is_a?(Array) && !data[:shipments].empty?

            create_package(shipment, data) if get_package_by_reference(shipment, data[:retailer_order_id]).nil?
          end

          def handle_order_status_change(shipment, data)
            # if the order is already delivered or canceled, we don't need to do anything
            return if shipment.delivered? || shipment.canceled?

            case data[:status]
            when ORDER_STATUSES[:pre_transit]
              create_package_if_not_exists(shipment, data)
            when ORDER_STATUSES[:in_transit]
              if shipment.can_transition_to?(:en_route)
                shipment.start_delivery!
                Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, '<- Shipment en route')
              elsif !shipment.en_route?
                raise StandardError, "Invalid state transition from #{shipment.state} to shipped"
              end
              create_package_if_not_exists(shipment, data)
            when ORDER_STATUSES[:completed]
              update_package(shipment, data)
            when ORDER_STATUSES[:canceled]
              if EXCEPTION_SUB_STATUSES.include?(data[:substatus])
                create_asana_task = ASANA_TASK_STATUSES.include?(data[:substatus])
                Dashboard::Integration::ThreeJMS::Notes.add_note(
                  shipment,
                  "<- Order Update: #{data[:status]}#{data[:substatus].present? ? " #{data[:substatus]}" : ''}",
                  create_asana_task,
                  create_asana_task ? [AsanaService::SHIPPING_ISSUE_TAG_ID] : []
                )
              end
              update_package(shipment, data)
            when ORDER_STATUSES[:confirmed]
              if !shipment.customer_placement_standard? && %w[pre_sale back_order].include?(shipment.state)
                Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, '<- Order confirmed. Trying to charge customer...')
                if Charges::ChargeOrderService.create_and_authorize_charges(shipment.order, [shipment]) && shipment.can_transition_to?(:confirmed)
                  shipment.confirm!
                  create_package_if_not_exists(shipment, data)
                else
                  add_do_not_ship_yet_note(shipment)
                  hold_order(shipment)
                end
              elsif shipment.can_transition_to?(:confirmed)
                shipment.confirm!
                create_package_if_not_exists(shipment, data)
              end
            else
              Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, "<- Order Update: #{data[:status]}#{data[:substatus].present? ? " #{data[:substatus]}" : ''}")
            end
          end

          def shipment_look_up(external_shipment_id, supplier = nil)
            shipment = if supplier.present?
                         Shipment.joins(:supplier)
                                 .where(suppliers: { id: supplier.id })
                                 .or(Shipment.where(suppliers: { delegate_supplier_id: supplier.id }))
                                 .where(external_shipment_id: external_shipment_id).first
                       else
                         Shipment.find_by(external_shipment_id: external_shipment_id)
                       end

            if shipment.nil? && split_order?
              package_reference = external_shipment_id
              external_id = package_reference.gsub(/-P\d$/, '')

              shipment = if supplier.present?
                           supplier.shipments.find_by!(external_shipment_id: external_id)
                         else
                           Shipment.find_by!(external_shipment_id: external_id)
                         end
            end

            raise ActiveRecord::RecordNotFound if shipment.nil?

            shipment
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
