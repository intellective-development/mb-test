class MaximumValue < Grape::Validations::Base
  def validate_param!(attr_name, params)
    raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message: "must be less than or equal to #{@option}" unless params[attr_name] <= @option
  end
end
