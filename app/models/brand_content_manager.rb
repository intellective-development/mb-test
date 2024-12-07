# == Schema Information
#
# Table name: brand_content_managers
#
#  id       :integer          not null, primary key
#  user_id  :integer          not null
#  brand_id :integer          not null
#
# Indexes
#
#  index_brand_content_managers_on_brand_id_and_user_id  (brand_id,user_id) UNIQUE
#

class BrandContentManager < ActiveRecord::Base
  has_paper_trail ignore: %i[created_at updated_at]

  belongs_to :brand
  belongs_to :user
end
