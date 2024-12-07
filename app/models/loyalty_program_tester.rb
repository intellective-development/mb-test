# == Schema Information
#
# Table name: loyalty_program_testers
#
#  id         :integer          not null, primary key
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_loyalty_program_testers_on_email  (email)
#

class LoyaltyProgramTester < ActiveRecord::Base
  def self.loyalty_program_tester?(email)
    enabled = ENV['LOYALTY_PROGRAM_ENABLED']
    enabled.present? && enabled != 'false' && exists?(email: email)
  end
end
