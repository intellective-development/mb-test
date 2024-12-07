# == Schema Information
#
# Table name: landing_pages
#
#  id         :integer          not null, primary key
#  permalink  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_landing_pages_on_permalink  (permalink) UNIQUE
#

class LandingPage < ActiveRecord::Base
  before_create :parameterize_permalink

  has_one :landing_page_content, dependent: :destroy
  alias_attribute :content, :landing_page_content
  validates :permalink, presence: true, uniqueness: true
  accepts_nested_attributes_for :landing_page_content

  private

  def parameterize_permalink
    self.permalink = permalink.parameterize
  end
end
