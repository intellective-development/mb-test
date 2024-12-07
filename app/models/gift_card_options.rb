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

class GiftCardOptions < ItemOptions
  after_create :generate_report

  def recipients=(recipients)
    if recipients.is_a?(String)
      super(recipients.split(',').map(&:squish))
    else
      super(recipients)
    end
  end

  def generate_report
    return unless order_items.first&.id

    coupons = Coupon.active.at(Time.zone.now).where(order_item_id: order_items.first.id)
    columns = %w[code amount recipient_email]

    CSV.generate do |csv|
      csv << columns
      coupons.each do |c|
        csv << [c.code, c.amount, c.recipient_email]
      end

      file = StringIO.new(csv.string)
      self.file = file
      self.file.instance_write(:file_name, 'gift_card_order_summary.csv')
      self.file.instance_write(:content_type, 'text/csv')
    end
    save!
  end

  def quantity
    (recipients.length if recipients.present?) || 0
  end

  def unapproved_gift_card_image?
    gift_card_image.present? && !gift_card_image.approved?
  end
end
