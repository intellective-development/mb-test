class Admin::OverviewsController < ApplicationController
  before_action :validate_admin
  layout 'admin'

  def index
    @supplier_orders = supplier_orders
    @stale_shipping_shipments = stale_shipping_shipments
    @stale_inventory = stale_inventory
    @store_turned_off = store_turned_off
  end

  private

  def supplier_orders
    @start_date = params[:start_date].present? ? DateTime.parse(params[:start_date]) : Time.zone.now
    @end_date = params[:end_date].present? ? DateTime.parse(params[:end_date]) : Time.zone.now
    @storefront_id = params[:storefront_id]

    Rails.cache.fetch("admin::overviews::supplier_orders::#{@start_date}::#{@end_date}::#{@storefront_id}", expires_in: 1.minute) do
      shipment_query = Shipment.joins(:supplier, :order).where(created_at: @start_date.beginning_of_day..@end_date.end_of_day,
                                                               state: ShipmentStateMachine::OVERVIEWS_STATES)
      shipment_query.where!(orders: { storefront_id: @storefront_id }) if @storefront_id.present?

      shipment_query.group(:name).order(count_all: :desc).limit(20).count
    end
  end

  def stale_shipping_shipments
    Rails.cache.fetch('admin::overviews::stale_shipping_shipments', expires_in: 1.minute) do
      Shipment.includes(:supplier, :order, user: :account)
              .joins(:shipping_method, :shipment_transitions)
              .left_joins(:tracking_detail, :packages)
              .where(shipment_transitions: { created_at: ..Time.zone.now - 5.days }, state: 'paid')
              .or(Shipment.where(state: 'confirmed',
                                 confirmed_at: ..Time.zone.now - 5.days,
                                 shipment_tracking_details: { id: nil },
                                 packages: { id: nil }))
              .where(shipping_methods: { shipping_type: 'shipped' },
                     shipment_transitions: { to_state: 'paid' })
              .order(Arel.sql('least(shipment_transitions.created_at, shipments.confirmed_at) asc'))
              .limit(100)
    end
  end

  def stale_inventory
    Rails.cache.fetch('admin::overviews::stale_inventory', expires_in: 1.minute) do
      Supplier.active
              .where(legacy_rb_paypal_supported: true,
                     last_inventory_update_at: ..(Time.zone.now - 5.days).end_of_day)
              .order(last_inventory_update_at: :asc)
    end
  end

  def store_turned_off
    Rails.cache.fetch('admin::overviews::store_turned_off', expires_in: 1.minute) do
      Supplier.inactive
              .where(deactivated_at: (Time.zone.now - 2.days).beginning_of_day..Time.zone.now.end_of_day)
              .order(deactivated_at: :asc)
    end
  end

  def validate_admin
    redirect_to admin_login_path unless current_user&.admin?
  end

  def session_args
    @session_args ||= { email: @user.email, password: @password }
  end
end
