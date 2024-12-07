class ZipcodeWaitlistListener < Minibar::Listener::Base
  subscribe_to ZipcodeWaitlist

  def zipcode_waitlist_created(zipcode_waitlist)
    WaitlistGeocodeWorker.perform_async(zipcode_waitlist.id)
  end
end
