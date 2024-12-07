# frozen_string_literal: true

class RedisStoreService
  require 'redis'
  attr_reader :parent_namespace

  REDIS_STORE_NAMESPACE = 'REDIS_STORE'

  def initialize(parent_namespace)
    @parent_namespace = parent_namespace
  end

  def set(key, *args)
    redis.set(namespace_key(key), *args)
    redis.expireat(namespace_key(key), default_expiration) # set a default expiry
  end

  def get(key, *args)
    redis.get(namespace_key(key), *args)
  end

  def exists(key, *args)
    redis.exists(namespace_key(key), *args)
  end

  def expireat(key, *args)
    redis.expireat(namespace_key(key), *args)
  end

  private

  def redis
    @redis ||= Redis.new
  end

  def namespace_key(key)
    "#{REDIS_STORE_NAMESPACE}::#{parent_namespace}::#{key}"
  end

  def default_expiration
    (Time.zone.now + 30.days).to_i
  end
end
