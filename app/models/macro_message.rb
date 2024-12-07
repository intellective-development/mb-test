# == Schema Information
#
# Table name: macro_messages
#
#  id         :integer          not null, primary key
#  name       :string
#  text       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  key        :string
#
class MacroMessage < ActiveRecord::Base
  TEXT_PARAMS_REGEX = /\{(.*?)}/.freeze

  validates :name, :text, presence: true
  validates :key, uniqueness: true, allow_nil: true

  def build_message(params)
    builded_text = text.dup

    param_keys = params.keys.map(&:to_s)
    if text_params.all? { |text_param| param_keys.include?(text_param) }
      params.each do |key, value|
        builded_text = builded_text.gsub("{#{key}}", value.to_s)
      end
    else
      missing_params = text_params - param_keys
      raise StandardError, "Missing params: (#{missing_params.join(', ')}) to build the Macro message text!"
    end

    builded_text
  end

  private

  def text_params
    return @text_params if defined?(@text_params)

    has_params = true
    tmp_text = text.dup
    @text_params = []

    while has_params
      text_param = tmp_text.slice(TEXT_PARAMS_REGEX, 1)
      if text_param.present?
        tmp_text = tmp_text.gsub("{#{text_param}}", '')
        @text_params << text_param
      else
        has_params = false
      end
    end

    @text_params
  end
end
