# frozen_string_literal: true

module CnameRecords
  # CnameRecords::Base
  class Base < BaseService
    attr_reader :cname_record

    def initialize(cname_record)
      @cname_record = cname_record
      super
    end
  end
end
