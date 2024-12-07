# == Schema Information
#
# Table name: item_options
#
#  id                      :integer          not null, primary key
#  type                    :string
#  sender                  :string
#  message                 :string
#  recipients              :text
#  send_date               :date
#  price                   :decimal(8, 2)
#  created_at              :datetime
#  updated_at              :datetime
#  gift_card_image_id      :integer
#  file_file_name          :string
#  file_content_type       :string
#  file_file_size          :integer
#  file_updated_at         :datetime
#  line1                   :string
#  line2                   :string
#  line3                   :string
#  line4                   :string
#  graphic_engraving_image :string
#
# Indexes
#
#  index_item_options_on_gift_card_image_id  (gift_card_image_id)
#
# Foreign Keys
#
#  fk_rails_...  (gift_card_image_id => gift_card_images.id)
#

class EngravingOptions < ItemOptions
  ENGRAVING_LINE_LIMIT = 4
  ENGRAVING_LINE_CHARACTER_LIMIT = 16

  def quantity
    nil
  end
end
