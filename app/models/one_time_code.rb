# == Schema Information
#
# Table name: one_time_codes
#
#  id         :integer          not null, primary key
#  code       :string           not null
#  purpose    :integer          not null
#  used       :boolean          default(FALSE), not null
#  order_id   :integer
#  used_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  metadata   :json
#

# This model is used for keeping track of one-time-codes such as entry codes for
# sweepstakes and other promotions.
class OneTimeCode < ActiveRecord::Base
  enum purpose: {
    abi_superbowl_sweepstake: 1,
    prize_logic: 2
  }

  scope :used,   -> { where(used: true) }
  scope :unused, -> { where(used: false) }
  scope :with_purpose, ->(purpose) { where('purpose = ?', OneTimeCode.purposes[purpose.to_sym]) }

  belongs_to :order
  has_one :user, through: :order

  validates :code, uniqueness: { case_sensitive: false }

  #-----------------------------------
  # Class methods
  #-----------------------------------

  def self.fetch_code(purpose_string, order_id = nil)
    code = OneTimeCode.with_purpose(purpose_string)
                      .unused
                      .order('random()')
                      .first

    code&.mark_as_used!(order_id)
    code
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def mark_as_used!(order_id = nil)
    raise 'Code has already been used' if used

    with_lock do
      self.order_id = order_id
      self.used_at = Time.zone.now
      self.used = true
      save!
    end
  end
end
