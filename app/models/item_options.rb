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

class ItemOptions < ActiveRecord::Base
  self.table_name = 'item_options'
  serialize :recipients, Array
  attr_accessor :resend, :new_send_date, :cc_sender

  belongs_to :gift_card_image
  has_many :order_items

  has_attached_file :file, BASIC_PAPERCLIP_OPTIONS.merge(
    path: 'gift_cards/:hash/report.csv',
    s3_headers: { 'Cache-Control' => 'max-age=315576000',
                  'Expires' => 10.years.from_now.httpdate,
                  'Content-Disposition' => 'attachment; filename=report.csv' }
  )

  validates_attachment :file, content_type: { content_type: 'text/csv' }

  validates :type, inclusion: { in: %w[GiftCardOptions EngravingOptions] }

  def quantity
    0
  end

  def unapproved_gift_card_image?
    false
  end

  def to_csv
    csv = "\"Email Address\"\n"
    csv += recipients.map { |recipient| "\"#{recipient}\"" }.join("\n")
    csv
  end
end
