# == Schema Information
#
# Table name: post_order_emails
#
#  id            :integer          not null, primary key
#  tag_name      :string(255)      not null
#  active        :boolean          default(FALSE), not null
#  template_slug :string(255)      not null
#  created_at    :datetime
#  updated_at    :datetime
#  subject       :string(255)
#
# Indexes
#
#  index_post_order_emails_on_tag_name  (tag_name)
#

class PostOrderEmail < ActiveRecord::Base
  auto_strip_attributes :tag_name, :template_slug

  belongs_to :tag, class_name: 'ActsAsTaggableOn::Tag', foreign_key: :tag_name, primary_key: :name
  validates :tag_name, presence: true, uniqueness: true
  validates :template_slug, presence: true

  scope :active, -> { where(active: true) }
end
