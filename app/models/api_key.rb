# == Schema Information
#
# Table name: api_keys
#
#  id         :integer          not null, primary key
#  token      :string           not null
#  consumer   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint(8)
#
# Indexes
#
#  index_api_keys_on_token    (token) UNIQUE
#  index_api_keys_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class APIKey < ActiveRecord::Base
  belongs_to :user

  validates :token, :consumer, presence: true
  validates :token, uniqueness: true

  before_validation :generate_token, on: :create

  private

  def generate_token
    return if token.present?

    loop do
      self.token = SecureRandom.hex(32)

      break unless APIKey.exists?(token: token)
    end
  end
end
