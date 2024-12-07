# == Schema Information
#
# Table name: storefront_links
#
#  id            :integer          not null, primary key
#  area          :integer          default("footer")
#  name          :string
#  url           :string
#  link_type     :integer
#  storefront_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class StorefrontLink < ActiveRecord::Base
  enum area: {
    footer: 0
  }

  enum link_type: {
    terms: 0,
    privacy_policy: 1,
    disclaimer: 2,
    faq: 3,
    membership_terms: 4
  }

  belongs_to :storefront

  has_paper_trail ignore: %i[created_at updated_at]

  validates :name, presence: true
  validates :url, presence: true
  validates :area, presence: true

  scope :by_name, ->(name) { where('name ILIKE :name', name: "%#{name}%") }
end
