# == Schema Information
#
# Table name: top_banner_messages
#
#  id                 :integer          not null, primary key
#  text               :text
#  created_at         :datetime
#  updated_at         :datetime
#  disabled           :boolean
#  url                :text
#  color              :text
#  permalinks_filters :string
#

class TopBannerMessage < ActiveRecord::Base
  scope :active, -> { where(disabled: [nil, false]) }

  def self.confirmation_email_bottom_banner
    find_by_id(6)
  end

  def self.confirmation_email_bottom_banner_with_permalinks_filter
    find_by_id(7)
  end

  def includes_permalink?(permalinks)
    permalinks_list.any? { |pl| permalinks.include?(pl) }
  end

  def permalinks_list
    return [] if permalinks_filters.blank?

    permalinks_filters.split(',').map(&:strip)
  end

  def confirmation_email_bottom_banner?
    # always consider that this model could not be saved
    id == 6 || id == 7
  end

  def configures_permalinks_filters?
    id == 7
  end

  def text?
    !disabled && text.present? && !text.empty?
  end
end
