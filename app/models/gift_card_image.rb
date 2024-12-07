# == Schema Information
#
# Table name: gift_card_images
#
#  id             :integer          not null, primary key
#  status         :integer
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  correlation_id :string
#  image_url      :string
#  thumb_url      :string
#  deleted_at     :datetime
#
# Indexes
#
#  index_gift_card_images_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class GiftCardImage < ActiveRecord::Base
  belongs_to :user

  enum status: {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  def approve!
    update(status: 'approved')
  end

  def reject!
    update(status: 'rejected')
  end
end
