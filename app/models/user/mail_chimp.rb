class User
  module MailChimp
    extend ActiveSupport::Concern

    included do
      after_commit :subscribe_to_mailchimp, unless: -> { ENV['MAILCHIMP_STATUS'] == 'DISABLED' }
    end

    def subscribe_to_mailchimp
      UserMailchimpProfileUpdateWorker.perform_async(id) unless partner_api_user?
    end

    def mailchimp_sync_data
      data = {
        email_address: email,
        status: 'subscribed',
        vip: vip,
        merge_fields: mailchimp_merge_fields
      }

      # We only want to include location attributes if they exist.
      if last_order&.ship_address&.latitude && last_order&.ship_address&.longitude
        data[:location] = {
          latitude: last_order&.ship_address&.latitude,
          longitude: last_order&.ship_address&.longitude
        }
      end
      data
    end

    def mailchimp_merge_fields
      {
        FNAME: first_name,
        LNAME: last_name,
        REFERRAL: referral_code,
        ZIPS: shipping_addresses.pluck(:zip_code).uniq.join(','),
        AVAIL_SM: shipping_addresses.flat_map(&:available_shipping_methods)&.map(&:shipping_type)&.uniq&.join(','),
        USED_SM: Address.where(id: orders.finished.pluck(:ship_address_id)).flat_map(&:available_shipping_methods)&.map(&:shipping_type)&.uniq&.join(','),
        CREATED: created_at.strftime('%m/%d/%Y'),
        LOGIN_AT: account.last_sign_in_at&.strftime('%m/%d/%Y'),
        ORDER_CNT: orders.finished.count,
        FIRST_ORDE: orders.finished.order(completed_at: :asc).first&.completed_at&.strftime('%m/%d/%Y'),
        LAST_ORDER: orders.finished.order(completed_at: :desc).first&.completed_at&.strftime('%m/%d/%Y'),
        LAST_SID: last_supplier.respond_to?(:id) ? last_supplier.id : last_supplier&.first&.id,
        TOP_REGION: profile&.top_region ? Region.find_by(id: profile.top_region)&.name : nil,
        CORPORATE: corporate ? 1 : 0,
        VIP: vip ? 1 : 0,
        FORDERPROD: profile&.mailchimp_first_order_product_type,
        TOP_CATEG: profile&.most_popular_category ? String(ProductType.find_by(id: profile.most_popular_category)&.name).downcase : nil,
        REGIONS: profile&.order_regions ? Region.where(id: profile.order_regions).pluck(:name).join(',') : nil,
        TOP_SUP: top_supplier,
        STATES: shipping_addresses.pluck(:state_name).uniq.join(','),
        VSELECT: shipping_addresses.any? { |address| address.all_suppliers.any?(&:vineyard_select?) } ? 1 : 0,
        VS_ONLY: shipping_addresses.any? && shipping_addresses.all?(&:dtc_only?) ? 1 : 0,
        SHIP_ONLY: shipping_addresses.any? && shipping_addresses.all?(&:shipping_only?) ? 1 : 0,
        LST_REGION: profile&.last_region ? Region.find_by(id: profile.last_region)&.name : nil,
        LAST_SNAME: last_supplier.respond_to?(:id) ? last_supplier.id : last_supplier&.first&.id # last_supplier is a collection for multi-supplier orders
      }.compact
    end

    private

    def top_supplier
      suppliers = shipments.pluck(:supplier_id)
      suppliers.max_by { |i| suppliers.count(i) }
    end
  end
end
