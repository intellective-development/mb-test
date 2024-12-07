class Profile
  class CleanupStaleProfileWorker
    include Sidekiq::Worker
    include WorkerErrorHandling

    sidekiq_options retry: false,
                    queue: 'backfill'

    def perform_with_error_handling
      Profile::CleanupStaleProfiles.new.call
    end
  end
end
