# == Schema Information
#
# Table name: external_wine_data
#
#  id         :integer          not null, primary key
#  product_id :integer
#  wine       :json
#  snooth     :json
#

class ExternalWineData < ActiveRecord::Base
  belongs_to :product
end
