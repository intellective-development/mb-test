# frozen_string_literal: true

# == Schema Information
#
# Table name: login_providers
#
#  id                    :bigint(8)        not null, primary key
#  registered_account_id :bigint(8)        not null
#  key                   :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_login_providers_on_key_and_registered_account_id  (key,registered_account_id) UNIQUE
#  index_login_providers_on_registered_account_id          (registered_account_id)
#
# Foreign Keys
#
#  fk_rails_...  (registered_account_id => registered_accounts.id)
#
class LoginProvider < ApplicationRecord
  belongs_to :registered_account, optional: false

  validates :key, uniqueness: { scope: :registered_account_id }

  scope :liquid, -> { where(table[:key].matches('liquid:%', nil, true)) }

  def liquid?
    key.include?('liquid:')
  end
end
