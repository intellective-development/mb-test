class ChangesetPresenter < BasePresenter
  delegate :name, to: :product_grouping,  prefix: true,   allow_nil: true
  delegate :name, to: :account,           prefix: 'user', allow_nil: true
  delegate :name, to: :brand,             prefix: true,   allow_nil: true
end
