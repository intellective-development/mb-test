class AddressBlacklist
  ALERT_BLACKLIST = [
    {
      address1: /40 Deepdale Drive/,
      zip_code: /07748/,
      state_name: 'NJ',
      reason: "Alcoholic and family doesn't want him receiving Minibar deliveries"
    }
  ].freeze

  BLOCK_BLACKLIST = [
    {
      address1: /17 Concord Drive/,
      zip_code: /07039/,
      state_name: 'NJ',
      reason: 'Fraudulent orders'
    },
    {
      address1: /8121 Northwest 68th Street/,
      zip_code: /33166/,
      state_name: 'FL',
      reason: 'Fraudulent orders'
    },
    {
      address1: /8952 Northwest 24th Terrace/,
      zip_code: /33172/,
      state_name: 'FL',
      reason: 'Fraudulent orders'
    },
    {
      address1: /2399 Bear Creek Drive/,
      zip_code: /34109/,
      state_name: 'FL',
      reason: 'Fraudulent orders'
    },
    {
      address1: /8086 Northwest 74th Avenue/,
      zip_code: /33166/,
      state_name: 'FL',
      reason: 'Fraudulent orders'
    },
    {
      address1: /6500 Northwest 84th Avenue/,
      zip_code: /33166/,
      state_name: 'FL',
      reason: 'Fraudulent orders'
    }
  ].freeze

  class << self
    def blacklisted_by_alert?(address)
      blacklist_reason(address, ALERT_BLACKLIST).present?
    end

    def blacklisted_by_block?(address)
      blacklist_reason(address, BLOCK_BLACKLIST).present?
    end

    def blacklist_reason(address, blacklist)
      return unless address.present?

      blacklist.find { |bl| address.address1.to_s =~ bl[:address1] && address.zip_code.to_s =~ bl[:zip_code] && address.state_name == bl[:state_name] }.try(:[], :reason)
    end
  end
end
