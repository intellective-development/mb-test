# == Schema Information
#
# Table name: promotions
#
#  id                           :integer          not null, primary key
#  internal_name                :string(255)      not null
#  display_name                 :string(255)      not null
#  starts_at                    :datetime
#  ends_at                      :datetime
#  active                       :boolean          default(TRUE), not null
#  type                         :string(255)      not null
#  promotable_type              :string(255)      not null
#  created_at                   :datetime
#  updated_at                   :datetime
#  target                       :text
#  position                     :integer          default(0)
#  image_file_name              :string(255)
#  image_content_type           :string(255)
#  image_file_size              :integer
#  image_updated_at             :datetime
#  image_width                  :integer
#  image_height                 :integer
#  match_tag                    :string(255)
#  match_product_type           :string(255)
#  match_search                 :string(255)
#  match_category               :string(255)
#  background_color             :string(255)
#  priority                     :integer
#  content_placement_id         :integer
#  exclude_logged_in_user       :boolean          default(FALSE)
#  secondary_image_file_name    :string(255)
#  secondary_image_content_type :string(255)
#  secondary_image_file_size    :integer
#  secondary_image_updated_at   :datetime
#  exclude_logged_out_user      :boolean
#  text_content                 :string(255)
#  match_page_type              :string(255)
#
# Indexes
#
#  index_promotions_on_content_placement_id  (content_placement_id)
#  index_promotions_on_id_and_type           (id,type)
#

class PromotionWebBanner < Promotion
  has_attached_file :image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'promotions/:id/:style/:basename.:extension')
  validates_attachment_size :image, less_than: 1.megabytes

  def eligible?(options = {})
    matchers_valid?(options)
  end

  def matchers_valid?(options)
    if options[:match_search].present?
      matcher_valid?(match_search, options[:match_search])
    elsif options[:type].present?
      matcher_valid?(match_product_type, options[:type])
    elsif options[:tag].present?
      matcher_valid?(match_tag, options[:tag])
    elsif options[:tag].blank?
      match_tag.blank?
    elsif options[:list_type].present?
      matcher_valid?(match_page_type, options[:list_type])
    else
      true
    end
  end

  def matcher_valid?(matcher, option)
    String(matcher).split(',').map(&:to_s).include?(String(option))
  end
end
