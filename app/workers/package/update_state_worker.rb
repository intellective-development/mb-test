class Package::UpdateStateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(package_id, new_state)
    package = Package.find(package_id)

    return unless package.can_transition_to?(new_state)

    package.transition_to!(new_state)
  end
end
