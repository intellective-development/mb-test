# == Schema Information
#
# Table name: package_transitions
#
#  id          :integer          not null, primary key
#  to_state    :string           not null
#  metadata    :json
#  sort_key    :integer          not null
#  package_id  :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_package_transitions_parent_most_recent  (package_id,most_recent) UNIQUE WHERE most_recent
#  index_package_transitions_parent_sort         (package_id,sort_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#

class PackageTransition < ActiveRecord::Base
  belongs_to :package, inverse_of: :package_transitions
end
