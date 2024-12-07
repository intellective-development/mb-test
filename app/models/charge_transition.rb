# == Schema Information
#
# Table name: charge_transitions
#
#  id          :integer          not null, primary key
#  to_state    :string(255)      not null
#  metadata    :json
#  sort_key    :integer          not null
#  charge_id   :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_charge_transitions_parent_most_recent  (charge_id,most_recent) UNIQUE WHERE most_recent
#  index_charge_transitions_parent_sort         (charge_id,sort_key) UNIQUE
#

class ChargeTransition < ActiveRecord::Base
  belongs_to :charge, inverse_of: :charge_transitions
end
