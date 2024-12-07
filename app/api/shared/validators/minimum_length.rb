class MinimumLength < Grape::Validations::Base
  def validate_param!(attr_name, params)
    raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be at least #{@option} characters long" unless params[attr_name].nil? || String(params[attr_name]).length >= @option
  end
end
