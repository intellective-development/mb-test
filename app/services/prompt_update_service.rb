# This service handles manual socket interactions with the supplier dashboard

class PromptUpdateService < SupplierNotificationServerService
  def initialize(suppliers, app_version)
    @app_version = app_version

    super(suppliers, 'prompt_update')
  end

  private

  def notification_content
    {
      entity_type: 'App',
      entity_id: @app_version,
      notification_type: @notification_type
    }
  end
end
