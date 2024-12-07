# frozen_string_literal: true

# BarOS
module BarOS
  REDIS_URL = ENV.fetch('BAR_OS_REDIS_URL', nil)

  class << self
    def table_name_prefix
      'bar_os_'
    end

    def cache
      return Rails.cache if REDIS_URL.blank?

      ActiveSupport::Cache::RedisCacheStore.new(url: REDIS_URL)
    end
  end
end
