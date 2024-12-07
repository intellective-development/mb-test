class CommentListener < Minibar::Listener::Base
  subscribe_to Comment

  def comment_created(comment, _ = {})
    CommentReminderWorker.perform_at(15.minutes.from_now, comment.id)
  end
end
