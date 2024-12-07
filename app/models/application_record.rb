class ApplicationRecord < ActiveRecord::Base
  include SentryNotifiable

  self.abstract_class = true

  def self.human_enum_name(enum_name, enum_value)
    enum_i18n_key = enum_name.to_s.pluralize
    I18n.t("activerecord.attributes.#{model_name.i18n_key}.#{enum_i18n_key}.#{enum_value}")
  end

  def self.enum_to_human_key_value_pair(enum_name, enum_key_values)
    enum_key_values.map do |key, _|
      [human_enum_name(enum_name, key), key]
    end
  end
end
