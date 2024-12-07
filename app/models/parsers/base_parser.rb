module Parsers
  class BaseParser
    require 'data_cleaners'

    include DataCleaner

    attr_accessor :products

    def self.new(args)
      instance = allocate # make memory space for a new object
      instance.send(:default_initialize, args)
      instance.send(:initialize, args)
      instance
    end

    def default_initialize(_args)
      @products = []
    end

    def initialize(args); end

    def parse
      raise 'Not Implemented'
    end
  end
end
