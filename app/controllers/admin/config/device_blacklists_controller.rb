class Admin::Config::DeviceBlacklistsController < Admin::Config::BaseController
  load_and_authorize_resource

  def index
    @device_blacklists = DeviceBlacklist.admin_grid(params)
  end

  def destroy
    @device_blacklist = DeviceBlacklist.find(params[:id])
    @device_blacklist.delete

    redirect_to admin_config_device_blacklists_path
  end

  private

  def allowed_params
    params.require(:device_blacklists).permit(:device_udid, :platform)
  end
end
