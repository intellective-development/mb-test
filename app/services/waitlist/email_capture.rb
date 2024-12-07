module Waitlist
  class EmailCapture
    attr_accessor :email

    def initialize(email)
      @email = email
    end

    def segment_id
      Digest::SHA256.hexdigest(String(email).downcase)
    end

    def as_segment_object
      {
        email: email,
        location: '$5 off modal'
      }
    end

    def as_segment_json
      {
        user_id: segment_id,
        traits: {
          email: email
        }
      }
    end
  end
end
