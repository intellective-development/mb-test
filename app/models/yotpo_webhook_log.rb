# == Schema Information
#
# Table name: yotpo_webhook_logs
#
#  id         :integer          not null, primary key
#  params     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  batch_id   :string
#  page       :integer
#  success    :boolean
#

class YotpoWebhookLog < ActiveRecord::Base
end
