class ExternalAPIV1::StorefrontOrdersEndpoint < ExternalAPIV1
  params do
    requires :uuid, type: String, desc: 'The UUID of a storefront'
  end

  resource :storefronts do
    before do
      @storefront = Storefront.find_by(uuid: params[:uuid])

      error!('Storefront not found', 404) if @storefront.nil?
    end

    desc 'Returns orders by storefront.'
    params do
      optional :email, type: String, desc: 'Email', allow_blank: false
      optional :phone, type: String, desc: 'Phone Number', allow_blank: false
      optional :gift_recipient_phone, type: String, desc: 'Gift Recipient Phone Number', allow_blank: false
      exactly_one_of :email, :phone, :gift_recipient_phone
    end
    get ':uuid/orders' do
      @orders = if params[:email].present?
                  orders_by_storefront_and_email(@storefront, params[:email])
                elsif params[:phone].present?
                  orders_by_storefront_and_phone_number(@storefront, params[:phone])
                elsif params[:gift_recipient_phone].present?
                  orders_by_storefront_and_gift_recipient_phone_number(@storefront, params[:gift_recipient_phone])
                end

      status 200
      present @orders, with: ExternalAPIV1::Entities::Order
    end
  end

  helpers do
    def orders_by_storefront_and_email(storefront, email)
      storefront.orders
                .joins(:user)
                .joins('inner join registered_accounts on registered_accounts.id = users.account_id')
                .where('lower(registered_accounts.email) = :email or lower(registered_accounts.contact_email) = :email', email: sanitize_email(email))
    end

    def orders_by_storefront_and_phone_number(storefront, phone_number)
      storefront.orders.joins(:ship_address).where(addresses: { phone: sanitize_phone_number(phone_number) })
    end

    def orders_by_storefront_and_gift_recipient_phone_number(storefront, phone_number)
      storefront.orders.joins(:gift_detail).where(gift_details: { recipient_phone: sanitize_phone_number(phone_number) })
    end

    def sanitize_email(email)
      email.downcase.squish
    end

    def sanitize_phone_number(phone_number)
      phone_number.gsub(/\s+/, '')
    end
  end
end
