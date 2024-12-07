require 'delegate'

# Because of using guid ids for the nested attributes we should define
# custom permit method. By default strong_parameters accept only numeric
# keys for the nested attributes in the fields_for form.

# Usage:
# params[:app][:nested_attributes] = NestedAttributesParameters.new(params[:app][:nested_attributes](
# params.require(:app).permit(nested_attributes: [:id, :attribute1, :attribute2] => { '51e52eb101790c31ba000001' => { 'id' => '51e52eb101790c31ba000001', 'attribute1' => 'value1', 'attribute2' => 'value2' } }  }

class NestedAttributesParameters < SimpleDelegator
  delegate :kind_of?, :is_a?, to: :__getobj__

  def initialize(hash)
    @hash = hash
  end

  def __getobj__
    @hash
  end

  def permit(*filters)
    @hash.each do |id, _value|
      @hash[id] = @hash[id].with_indifferent_access.slice(*filters)
    end
    @hash
  end
end
