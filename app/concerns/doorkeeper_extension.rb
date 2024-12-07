module DoorkeeperExtension
  extend ActiveSupport::Concern

  included do
    # validates :capture_defaults_on_authorization, presence: true
  end
end

Doorkeeper::Application.include DoorkeeperExtension
