class ApiErrorHandler < Grape::Middleware::Base
  def rack_response(message, status, headers = {})
    Rack::Response.new([message], Rack::Utils.status_code(status), headers)
  end

  def call!(env)
    @env = env
    begin
      @app.call(@env)
    rescue ActionController::BadRequest => e
      throw :error, message: e.message || options[:default_message], status: 400
    end
  end
end
