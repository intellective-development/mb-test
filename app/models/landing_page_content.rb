# == Schema Information
#
# Table name: landing_page_contents
#
#  id               :integer          not null, primary key
#  landing_page_id  :integer
#  headline         :string
#  subheadline_1    :string
#  subheadline_2    :string
#  page_title       :string
#  meta_description :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  legal            :text
#
# Indexes
#
#  index_landing_page_contents_on_landing_page_id  (landing_page_id)
#
# Foreign Keys
#
#  fk_rails_...  (landing_page_id => landing_pages.id)
#

class LandingPageContent < ActiveRecord::Base
  belongs_to :landing_page
end
