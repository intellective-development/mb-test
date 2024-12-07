class ValuesNotEqualValidator < ActiveModel::EachValidator
  def validate(record)
    return true if record.id.nil?

    @past = {}
    super
  end

  def validate_each(record, attribute, value)
    @past.each do |k, v|
      record.errors.add(attribute, "should not be equal to #{record.class.human_attribute_name(k)}") if v == value
    end
    @past[attribute] = value
  end
end
