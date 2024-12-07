# == Schema Information
#
# Table name: working_hours
#
#  id        :integer          not null, primary key
#  wday      :integer          not null
#  off       :boolean          default(FALSE), not null
#  starts_at :string
#  ends_at   :string
#

class WorkingHour < ActiveRecord::Base
end
