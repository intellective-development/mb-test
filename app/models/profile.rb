# == Schema Information
#
# Table name: profiles
#
#  id                          :integer          not null, primary key
#  ordered_types               :integer          default([]), is an Array
#  ordered_categories          :integer          default([]), is an Array
#  ordered_subtypes            :integer          default([]), is an Array
#  max_price                   :float            default(0.0)
#  min_price                   :float            default(0.0)
#  most_popular_category       :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  address_regions             :integer          default([]), is an Array
#  order_regions               :integer          default([]), is an Array
#  top_region                  :integer
#  most_popular_type           :integer
#  last_region                 :integer
#  gender                      :integer          default("unknown")
#  recently_ordered_types      :integer          default([]), is an Array
#  recently_ordered_categories :integer          default([]), is an Array
#  recently_ordered_subtypes   :integer          default([]), is an Array
#  most_ordered_types          :integer          default([]), is an Array
#  most_ordered_categories     :integer          default([]), is an Array
#  most_ordered_subtypes       :integer          default([]), is an Array
#  last_delta_update           :datetime
#  last_full_update            :datetime
#  viewed_categories           :integer          default([]), is an Array
#  viewed_types                :integer          default([]), is an Array
#  viewed_subtypes             :integer          default([]), is an Array
#  added_categories            :integer          default([]), is an Array
#  added_types                 :integer          default([]), is an Array
#  added_subtypes              :integer          default([]), is an Array
#

class Profile < ActiveRecord::Base
  has_one :user
  has_one :visit

  before_create :set_last_full_update

  enum gender: {
    unknown: 0,
    female: 1,
    male: 2
  }

  # This triggers a MailChimp automation based on the bucket a user falls in to.
  # Possible buckets are: red, white, sparkling, beer, liquor, mixed
  def mailchimp_first_order_product_type
    first_order_items = user.first_order&.order_items
    return nil unless first_order_items

    categories = first_order_items.each_with_object(Hash.new(0)) do |v, h|
      h[v&.variant&.hierarchy_category&.name] += v.quantity
      h
    end
    case categories.max_by { |v| categories[v] }[0]
    when 'beer' then 'beer'
    when 'liquor' then 'liquor'
    else
      types = first_order_items.each_with_object(Hash.new(0)) do |v, h|
        h[v&.variant&.hierarchy_type&.name] += v.quantity
        h
      end
      case types.max_by { |v| categories[v] }[0]
      when 'red' then 'red'
      when 'white' then 'white'
      when 'sparkling' then 'sparkling'
      else 'mixed'
      end
    end
  end

  def one_signal_tags
    tags = []

    tags << { user: true }
    tags << { corporate: user.corporate }
    tags << { vip: user.vip }
    tags << { orders: user.orders.finished.count }
    tags << { top_region: Region.find_by(id: top_region)&.name }
    tags << { top_category: ProductType.find_by(id: most_popular_category)&.name }
    tags << { employee: true } if user.email.include?('@minibardelivery.com')

    order_regions.each do |region_id|
      region = Region.find_by(id: region_id)
      tags << { "region_#{region.name.parameterize}" => true } if region
    end

    tags
  end

  private

  def set_last_full_update
    self.last_full_update = Time.zone.now
  end
end
