class DeviceBlacklist
  class AddDevices
    def initialize(user_id)
      @user = User.find(user_id)
    end

    def call
      @user.orders.pluck(:device_udid).compact.uniq.each do |device_id|
        DeviceBlacklist.find_or_create_by(device_udid: device_id)
      end
    end
  end
end
