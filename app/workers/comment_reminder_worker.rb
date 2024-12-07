class CommentReminderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'internal'

  def perform_with_error_handling(comment_id)
    comment = Comment.find(comment_id)
    comment.send_reminder
  end
end
