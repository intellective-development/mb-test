class Profile
  class CleanupStaleProfiles
    def initialize; end

    # This service allows us to periodically prune our stored personalization
    # profiles. We are specifically looking for ones which match the following:
    #
    #   1. Profile belongs to an anonymous visitor, not a real user.
    #   2. Profile has not been updated in 30 days.
    #
    # Note: Since Visits and Profiles reside in separate databases, we need to
    #       perform two queries in order to accurately identify stale profiles.
    def call
      visits = Visit.includes(:profile)
                    .where('started_at < ?', 60.days.ago)
                    .where(user_id: nil)
                    .where.not(profile_id: nil)

      visits.find_each do |visit|
        next unless visit.profile.present? || visit.profile&.last_delta_update || visit.last_full_update > 30.days.ago

        visit.profile.destroy
        visit.update(profile_id: nil)
      end
    end
  end
end
