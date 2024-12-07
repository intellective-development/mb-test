class Supplier
  module Notifications
    def notify_by?(type)
      notification_methods.send(type).active.exists?
    end
  end
end
