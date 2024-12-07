class DeviceBlacklist
  class RemoveDevices
    def initialize(user_id)
      @user = User.find(user_id)
    end

    def call
      device_ids = @user.orders.pluck(:device_udid).compact.uniq

      DeviceBlacklist.where(device_udid: device_ids).destroy_all
    end
  end
end
