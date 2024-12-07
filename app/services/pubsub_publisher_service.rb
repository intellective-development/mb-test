# frozen_string_literal: true

# This service is used to publish messages to GCloud PubSub topics
class PubsubPublisherService
  # Publishes a message to a PubSub topic
  # @param topic_name [String] the name of the PubSub topic
  # @param message [String] the message to publish
  def self.publish_message(topic_name, message)
    pubsub = Google::Cloud::Pubsub.new
    topic = pubsub.topic topic_name

    raise StandardError, 'Invalid PubSub topic name' if topic.nil?

    topic.publish message
  end
end
