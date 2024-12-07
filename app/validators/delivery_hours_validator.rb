class DeliveryHoursValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'is before starts_at.') if Time.zone.parse(value) < Time.zone.parse(record.starts_at)
  end
end
