class Admin::Config::WorkingHoursController < Admin::Config::BaseController
  load_and_authorize_resource

  def index; end

  def update_multiple
    if WorkingHour.update(params[:working_hours].keys, params[:working_hours].values)
      redirect_to(admin_config_working_hours_path, notice: 'Working Hours was successfully updated.')
    else
      redirect_to(admin_config_working_hours_path, notice: 'Working Hours update error!')
    end
  end
end
