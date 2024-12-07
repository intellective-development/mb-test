# frozen_string_literal: true

class BaseService
  include SentryNotifiable

  private_class_method :new

  def initialize(*args); end

  def self.call(*args)
    new(*args).call
  end
end
