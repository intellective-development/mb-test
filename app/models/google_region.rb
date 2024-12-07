# == Schema Information
#
# Table name: google_regions
#
#  id              :integer          not null, primary key
#  region_id       :string
#  state           :string
#  default_address :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_google_regions_on_region_id  (region_id)
#
class GoogleRegion < ActiveRecord::Base
  # This class manages region_id vs which suppliers should we show in FRONTEND
  # Currently a region_id is basically a shipped state (like NY or CA)
  # attribute region_id IS GOOGLE'S region_id in Google Shopping
end
