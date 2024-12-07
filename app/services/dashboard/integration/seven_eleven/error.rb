module Dashboard
  module Integration
    module SevenEleven
      module Error
        module ErrorCodes
          # Errors defined by 7NOW:
          INVALID_REQUEST_FORMAT       = '0400'.freeze # Invalid request format
          ITEM_UNAVAILABLE             = '0401'.freeze # One or more items unavailable
          STORE_UNAVAILABLE            = '0402'.freeze # Store is down
          ITEM_PRICE_MISMATCH          = '0403'.freeze # One or more items price changed
          INVALID_SOURCE               = '0405'.freeze # Invalid source
          INVALID_PROMO                = '0406'.freeze # Invalid promo
          INVALID_ADDRESS              = '0407'.freeze # Invalid address
          ITEM_RESTRICTED_SALE_HOURS   = '0409'.freeze # Restricted alcohol sale hours
          MISSING_INFO_USER_PROFILE    = '0410'.freeze # Missing information in user_profile
          ORDER_ALREADY_EXISTS         = '0500'.freeze # Order already exists
          UNSUPPORTED_DELIVERY_ADDRESS = '0101'.freeze # The order cannot be delivered to the user's address
          TAX_ENGINE_ISSUE             = '0205'.freeze # TaxEngine Issue
        end

        class StandardError < Dashboard::Integration::Errors::StandardError
          attr_accessor :error_code

          def initialize(message, error_code = nil)
            super(message)
            @error_code = error_code

            unless @error_code.nil?
              available_error_codes = ErrorCodes.constants.map { |c| ErrorCodes.const_get c }
              Rails.logger.error "SevenEleven::Error::StandardError was created using unknown error code: '#{@error_code}'" unless available_error_codes.include?(@error_code)
            end
          end
        end

        class ExceededItemsLimitError < StandardError
          attr_accessor :allowed_count

          def initialize(message, error_code = nil, allowed_count = nil)
            super(message, error_code)
            @allowed_count = allowed_count
          end
        end

        class StoreUnavailableError < StandardError
          attr_accessor :supplier_id, :store_name

          def initialize(message, error_code = nil, supplier_id = nil, store_name = nil)
            super(message, error_code)
            @supplier_id = supplier_id
            @store_name = store_name
          end
        end

        class ItemError < StandardError
          attr_accessor :item_id, :item_sku, :item_name, :item_available_qty, :item_current_price, :item_requested_qty, :external_name

          def initialize(message, error_code, item_id, item_sku, item_name, item_requested_qty = nil, item_available_qty = nil, item_current_price = nil, external_name = nil) # rubocop:disable Metrics/ParameterLists
            super(message, error_code)
            @item_id = item_id
            @item_sku = item_sku
            @item_name = item_name
            @external_name = external_name
            @item_requested_qty = item_requested_qty
            @item_available_qty = item_available_qty
            @item_current_price = item_current_price
          end
        end
      end
    end
  end
end
