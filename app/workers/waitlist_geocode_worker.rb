class WaitlistGeocodeWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(zipcode_waitlist_id)
    zipcode_waitlist = ZipcodeWaitlist.find(zipcode_waitlist_id)
    zipcode_waitlist.geocode
  end
end
