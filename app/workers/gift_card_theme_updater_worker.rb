class GiftCardThemeUpdaterWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'internal'

  def perform_with_error_handling(theme_id)
    gift_card_theme = GiftCardTheme.find(theme_id)
    GiftCardThemeUpdaterService.new(gift_card_theme).update!
  end
end
