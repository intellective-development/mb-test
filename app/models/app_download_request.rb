# == Schema Information
#
# Table name: app_download_requests
#
#  id                   :integer          not null, primary key
#  phone_number         :string           not null
#  last_message_sent_at :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_app_download_requests_on_phone_number  (phone_number) UNIQUE
#
class AppDownloadRequest < ActiveRecord::Base
  phony_normalize :phone_number

  validates :phone_number, phony_plausible: true
end
