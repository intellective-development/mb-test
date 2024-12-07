class Package::StateMachine
  include Statesman::Machine
  include Statesman::Events

  state :pending, initial: true
  state :en_route
  state :delivered
  state :exception

  event :deliver do
    transition from: :pending, to: :delivered
    transition from: :en_route, to: :delivered
    transition from: :exception, to: :delivered
  end

  event :start_delivery do
    transition from: :pending, to: :en_route
    transition from: :exception, to: :en_route
  end

  event :exception do
    transition from: :en_route, to: :exception
    transition from: :pending, to: :exception
  end

  after_transition do |package, transition|
    package.update! state: transition.to_state
  end

  after_transition(to: :delivered, after_commit: true) do |package, _transition|
    package.broadcast_event(:package_delivered)
  end

  after_transition(to: :en_route, after_commit: true) do |package, _transition|
    package.broadcast_event(:package_en_route)
  end
end
