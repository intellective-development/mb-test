class BirthDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'is too young.') unless value.age >= 21
    record.errors.add(attribute, 'is too old.')   unless value.age < 110
  end
end
