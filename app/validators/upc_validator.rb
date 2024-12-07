class UPCValidator < ActiveModel::EachValidator
  require 'upc'

  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'is not a valid UPC.') unless UPC.valid?(value)
  end
end
