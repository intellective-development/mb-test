# frozen_string_literal: true

# == Schema Information
#
# Table name: device_blacklists
#
#  id          :integer          not null, primary key
#  device_udid :string(255)
#  platform    :integer          default("iphone")
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_device_blacklists_on_device_udid_and_platform  (device_udid,platform)
#

class DeviceBlacklist < ActiveRecord::Base
  enum platform: {
    iphone: 0,
    ipad: 1,
    android: 2,
    web: 3,
    iphone_web: 4,
    ipad_web: 5,
    android_web: 6
  }

  IOS_DEFAULT_UDID = '00000000-0000-0000-0000-000000000000'

  def self.blacklisted?(udid)
    return false if udid.nil?
    return false if udid == IOS_DEFAULT_UDID

    DeviceBlacklist.exists?(device_udid: udid)
  end

  def self.admin_grid(params = {})
    grid = DeviceBlacklist.public_send(Kaminari.config.page_method_name, params[:page] || 1)
                          .per(params[:per_page] || 100)
                          .order(created_at: :desc)
    grid = grid.where('device_udid ILIKE ?', "%#{params[:search].squish.downcase}%") if params[:search].present?
    grid
  end
end
