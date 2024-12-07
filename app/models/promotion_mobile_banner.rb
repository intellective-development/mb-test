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

class PromotionMobileBanner < Promotion
  has_attached_file :image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'promotions/:id/:style/:basename.:extension')
  validates_attachment_size :image, less_than: 1.megabytes

  validates :priority, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }

  def eligible?(options = {})
    matchers_valid?(options)
  end

  def matchers_valid?(options)
    ## We want to match options to promotions:
    ## options that don't have any criterias should only match promotions that don't have any criterias (match_page_type, match_product_type, match_tag, match_search)
    ## options that include criterias should match promotions that include these criterias
    ## match_tag is a csv string - it is a tag for tag lists
    ## match_page_type is csv string - compared to list_type
    ## match_product_type is a csv string - compared to hierarchy_type
    ## match_search is a csv string

    matcher_valid_by_product_type?(options[:type]) && matcher_valid_by_tag?(options[:tag]) && matcher_valid_by_page_type?(options[:list_type])
  end

  def matcher_valid_by_product_type?(type)
    (match_product_type.blank? && type.blank?) || match_product_type.split(',').map(&:to_s).include?(type.to_s)
  end

  def matcher_valid_by_tag?(tag)
    (match_tag.blank? && tag.blank?) || match_tag.split(',').map(&:to_s).include?(tag.to_s)
  end

  def matcher_valid_by_page_type?(list_type)
    (match_page_type.blank? && list_type.blank?) || match_page_type.split(',').map(&:to_s).include?(list_type.to_s)
  end
end
