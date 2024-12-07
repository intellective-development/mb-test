require 'sitemap_generator'

class GenerateSitemapWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: :backfill

  def perform_with_error_handling
    return unless ENV['SITEMAP_ENABLED']

    SitemapGenerator::Interpreter.run
  end
end
