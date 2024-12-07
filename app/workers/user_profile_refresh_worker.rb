class UserProfileRefreshWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'backfill'

  def perform_with_error_handling
    User.joins(:profile).where.not(profiles: { last_full_update: nil }).where('profiles.last_full_update < ?', 30.days.ago).order('profiles.last_full_update asc').limit(50_000).find_each do |user|
      UserProfileUpdateWorker.perform_async(user.id)
    end
  end
end
