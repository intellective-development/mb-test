# == Schema Information
#
# Table name: comments
#
#  id                :integer          not null, primary key
#  note              :text
#  commentable_type  :string(255)
#  commentable_id    :integer
#  created_by        :integer
#  user_id           :integer
#  created_at        :datetime
#  updated_at        :datetime
#  posted_as         :integer
#  file_file_name    :string
#  file_content_type :string
#  file_file_size    :bigint(8)
#  file_updated_at   :datetime
#  external_file     :string
#
# Indexes
#
#  index_comments_on_commentable_id_and_commentable_type  (commentable_id,commentable_type)
#  index_comments_on_user_id                              (user_id)
#

class Comment < ActiveRecord::Base
  include WisperAdapter

  belongs_to :commentable, polymorphic: true, touch: true
  belongs_to :author, class_name: 'User', foreign_key: 'created_by'
  belongs_to :user, counter_cache: true

  validates :note,              presence: true, length: { maximum: 1255 }
  validates :commentable_type,  presence: true

  has_attached_file :file, BASIC_PAPERCLIP_OPTIONS.merge(
    path: 'comments/:id/:basename.:extension',
    default_url: ''
  )
  do_not_validate_attachment_file_type :file

  after_commit :publish_comment_created, on: :create

  enum posted_as: {
    minibar: 0,
    supplier: 1
  }

  attr_accessor :liquid

  def publish_comment_created
    broadcast(:comment_created, self, liquid: (liquid.presence || false))
  end

  def order
    case commentable_type
    when 'Order'
      commentable
    when 'Shipment'
      commentable.order
    end
  end

  def d_commentable_type
    case commentable_type
    when 'Order'
      'Order/Internal'
    when 'Shipment'
      'Supplier'
    when 'User'
      'Customer'
    else
      commentable_type
    end
  end

  def send_reminder
    broadcast(:comment_reminder, self) if should_remind?
  end

  def should_remind?
    # We want to trigger a reminder if the comment was posted by Minibar, and there has not been a subsequent supplier comment
    # acknowledging reciept within 15 minutes.
    posted_by_minibar? && commentable_type == 'Shipment' && last_comment? && !note.include?('SENT TO CUSTOMER') && !commentable.confirmed?
  end

  def last_comment?
    commentable.comments.last.id == id
  end

  def posted_by_minibar?
    author&.admin? || author&.super_admin?
  end

  def posted_by_supplier?
    author&.supplier?
  end

  def posted_by_delivery_service?
    author&.delivery_service?
  end

  def asana_notification_params
    return unless note.include?('Order has been returned') ||
                  note.include?('Delivery order has successfully canceled') ||
                  note.include?('DoorDash is not open for delivery at the requested pickup_time') ||
                  note.include?('Phone number provided does not seem to be a valid one')

    {
      name: "DELIVERY ERROR: Order #{commentable.order_number} - #{commentable.user_name}",
      notes: "Order with supplier #{commentable.supplier_name} had an error:\n" \
               "NOTE: #{note}\n\n" \
               "Order: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{commentable.order_id}/edit",
      tags: [AsanaService::COMMENT_TAG_ID]
    }
  end

  def updateble?
    author.present? &&
      !author.supplier? &&
      !author.email.include?('integration@minibardelivery.com') &&
      !(commentable.is_a?(Shipment) && commentable.dashboard_type == Supplier::DashboardType::THREE_JMS)
  end

  def file_url
    return external_file if external_file.present?
    return file.url(:original, false) if file.present?

    nil
  end
end
