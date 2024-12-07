class SupplierAPIV2::SupplierEndpoint < BaseAPIV2
  helpers do
    def get_period
      case params[:period]
      when '30min'
        30.minutes
      when '1hr'
        1.hour
      when '2hrs'
        2.hours
      when '24hrs'
        24.hours if current_supplier.eligible_for_longer_breaks?
      when '48hrs'
        48.hours if current_supplier.eligible_for_longer_breaks?
      end
    end

    def get_delivery_expectations
      delivery_expectation = nil
      delivery_expectation_maximum = 60
      case params[:delivery_expectation]
      when '-1hr'
        delivery_expectation = 'Delivery under an hour'
        delivery_expectation_maximum = 60
      when '60_to_120mins'
        delivery_expectation = 'Delivery in 60-120 minutes'
        delivery_expectation_maximum = 120
      when '60_to_90mins'
        delivery_expectation = 'Delivery in 60-90 minutes'
        delivery_expectation_maximum = 90
      when '90_to_120mins'
        delivery_expectation = 'Delivery in 90-120 minutes'
        delivery_expectation_maximum = 120
      when '120_to_150mins'
        delivery_expectation = 'Delivery in 2-2.5 hours'
        delivery_expectation_maximum = 150
      when '150_to_180mins'
        delivery_expectation = 'Delivery in 2.5-3 hours'
        delivery_expectation_maximum = 180
      end

      { delivery_expectation: delivery_expectation, delivery_expectation_maximum: delivery_expectation_maximum }
    end

    def create_delivery_expectation_exceptions(period, delivery_expec_params)
      on_demand_shipping_methods = ShippingMethod.active.on_demand.where(supplier_id: current_supplier.id)
      on_demand_shipping_methods.each do |sm|
        delivery_expectation_exception = DeliveryExpectationException.new
        delivery_expectation_exception.shipping_method = sm
        delivery_expectation_exception.start_date = Time.now
        delivery_expectation_exception.end_date = Time.now + period
        delivery_expectation_exception.delivery_expectation = delivery_expec_params[:delivery_expectation]
        delivery_expectation_exception.maximum_delivery_expectation = delivery_expec_params[:delivery_expectation_maximum]
        delivery_expectation_exception.save
      end
    end

    def mark_shipments_as_late
      ShippingMethod.active.on_demand.where(supplier_id: current_supplier.id).each do |sm|
        shipments = Shipment.on_demand.where(shipping_method_id: sm.id, state: %w[ready_to_ship paid confirmed]).where("shipments.created_at > '#{2.days.ago}'")
        shipments.each(&:process_late_shipment)
      end
    end
  end

  namespace :me do
    get do
      authorize!
      present current_user, with: SupplierAPIV2::Entities::Me
    end
  end

  desc 'Returns currently loaded supplier.'
  namespace :supplier do
    get do
      present current_supplier, with: SupplierAPIV2::Entities::Supplier
    end

    namespace :notification_methods do
      get do
        present current_supplier.notification_methods, with: SupplierAPIV2::Entities::NotificationMethod
      end
    end
    namespace :notification_method do
      params do
        requires :notification_type, type: String
        requires :value,             type: String
        optional :label,             type: String
        optional :active,            type: Boolean, default: true
      end
      post do
        notification_method = current_supplier.notification_methods.find_or_create_by(params.slice(:notification_type, :value, :active, :label))

        present notification_method, with: SupplierAPIV2::Entities::NotificationMethod
      end
      route_param :notification_method_id do
        before do
          authorize!
          @notification_method = current_supplier.notification_methods.find(params[:notification_method_id])
          error!('Notification method not found.', 404) unless @notification_method
        end
        params do
          optional :notification_type, type: String
          optional :value,             type: String
          optional :active,            type: Boolean
          optional :label,             type: String
          at_least_one_of :notification_type, :value, :active, :label
        end
        put do
          @notification_method.update(params.slice(:notification_type, :value, :active, :label))
          present @notification_method, with: SupplierAPIV2::Entities::NotificationMethod
        end
        get do
          present @notification_method, with: SupplierAPIV2::Entities::NotificationMethod
        end
        delete do
          @notification_method.destroy
        end
      end
    end

    namespace :config do
      get do
        present current_supplier.config, with: SupplierAPIV2::Entities::Config
      end
      params do
        requires :email_tip, type: Boolean
      end
      put do
        current_supplier.config = current_supplier.config.merge(params.slice(:email_tip))

        if current_supplier.save
          present current_supplier.config, with: SupplierAPIV2::Entities::Config
        else
          error!(current_supplier.errors.full_messages, 400)
        end
      end
    end

    namespace :messages do
      params do
        requires :type, type: String
        requires :body, type: String
      end
      post do
        SupplierUpdateNotificationJob.perform_later(name: current_supplier.name,
                                                    email: current_supplier.email,
                                                    subject: "[Ops] Message from #{current_supplier.name}: #{params[:type]}",
                                                    description: params[:body],
                                                    type: params[:type])

        status 200
        present :status, 'sent'
      end
    end

    namespace :employees do
      get do
        present current_supplier.employees.excluding_minibar_employees, with: SupplierAPIV2::Entities::Employee
      end
    end

    namespace :employee do
      params do
        requires :first_name, type: String
        requires :last_name,  type: String
        requires :email,      type: String
        requires :password,   type: String
        requires :password_confirmation, type: String
        optional :role
      end
      post do
        user = User.new(
          anonymous: false,
          account_attributes: {
            first_name: params[:first_name],
            last_name: params[:last_name],
            email: params[:email],
            password: params[:password],
            password_confirmation: params[:password_confirmation],
            storefront_id: Storefront::MINIBAR_ID # TODO: in future we may need to set different storefronts here
          }
        )
        if user.save
          if params[:role] == 'driver'
            user.roles.add(:driver)
          else
            user.roles.add(:supplier)
          end
          user.save
          user.employee_of_supplier(current_supplier.id)
          user.employee.activate!

          present user.employee, with: SupplierAPIV2::Entities::Employee
        else
          error!(user.errors.full_messages, 400)
        end
      end

      route_param :employee_id do
        before do
          authorize!

          @employee = current_supplier.employees.find_by(id: params[:employee_id])
          error!('Employee not found.', 404) unless @employee
        end
        get do
          present @employee, with: SupplierAPIV2::Entities::Employee
        end
        params do
          optional :first_name, type: String
          optional :last_name,  type: String
          optional :email,      type: String
          optional :active,     type: Boolean
        end
        put do
          account = @employee.account
          account.first_name = params[:first_name]  if params[:first_name].present?
          account.last_name  = params[:last_name]   if params[:last_name].present?
          account.email      = params[:email]       if params[:email].present?

          state = params[:active]
          state = @employee.active if state.nil?
          state ? @employee.activate! : @employee.deactivate!

          if @employee.save && account.save
            present @employee, with: SupplierAPIV2::Entities::Employee
          else
            error!(account.errors.full_messages, 400)
          end
        end
        delete do
          error!('You cannot delete yourself', 400) if @employee == current_user.employee

          @employee.roles.delete(:supplier)
          @employee.destroy
          present current_supplier.employees, with: SupplierAPIV2::Entities::Employee
        end
        namespace :actions do
          namespace :reset_password do
            put do
              # TODO: JM: This feels fragile with all the chaining assumptions.
              @employee.account.send_reset_password_instructions

              status 200
              present @employee, with: SupplierAPIV2::Entities::Employee
            end
          end
        end
      end
    end

    namespace :actions do
      namespace :ping do
        get do
          unconfirmed_shipments = Shipment.joins(:order)
                                          .where(supplier_id: current_supplier_ids)
                                          .where(
                                            'orders.state in (:order_visible_states) AND '\
                                            'shipments.state in (:unconfirmed_state) OR '\
                                            '(shipments.state = :scheduled_state AND shipments.scheduled_for <= :scheduling_cutoff)',
                                            unconfirmed_state: %w[ready_to_ship paid],
                                            order_visible_states: Order::SUPPLIER_VISIBLE_STATES,
                                            scheduled_state: 'scheduled',
                                            scheduling_cutoff: Time.zone.now.in_time_zone(current_supplier.timezone) + Shipment::SCHEDULING_BUFFER.hours
                                          )
                                          .pluck(:uuid)

          present unconfirmed_shipments: unconfirmed_shipments
        end
      end

      namespace :break do
        post do
          @break = SupplierBreak.new(supplier: current_supplier, user: current_user)
          @break.period = get_period
          @break.save

          present current_supplier, with: SupplierAPIV2::Entities::Supplier
        end
      end

      namespace :resume do
        post do
          current_break = current_supplier.supplier_breaks.upcoming.first
          current_break&.delete if current_break&.date == Time.zone.now.in_time_zone(current_supplier.timezone).strftime('%m/%d/%Y')
          present current_supplier, with: SupplierAPIV2::Entities::Supplier
        end
      end

      namespace :late do
        post do
          period = get_period
          delivery_expec_params = get_delivery_expectations

          create_delivery_expectation_exceptions(period, delivery_expec_params)
          mark_shipments_as_late

          present current_supplier, with: SupplierAPIV2::Entities::Supplier
        end
      end
    end
  end
end
