# Standardised Wisper even broadcasting.
module WisperAdapter
  def self.included(base)
    base.include(Wisper::Publisher) unless base.included_modules.include?(Wisper::Publisher)
    base.extend(ClassMethods)
  end

  # broadcast and event from the instance
  #
  # @example
  #   class Order < AR::Base
  #     include WisperAdapter
  #   end
  #
  #   order = Order.create
  #   order.broadcast_event(:order_created)
  #
  # This is useful inside a statesman callback
  #
  # @example
  #   after_transition to: :paid do |order, transition|
  #     order.broadcast_event(:order_paid)
  #   end
  #
  # If prefix: true is passed the event will be prefixed with the class singular name.
  #
  # @example
  #
  #   order.broadcast_event(:created, prefix: true)
  #
  # Useful inside Statesman state machines;
  #
  #   after_transition after_commit: true do |object, transition|
  #     object.broadcast_event(transition.to_state, prefix: true)
  #   end
  #
  #   order.transition_to(:paid)
  #
  # Broadcasts 'order_paid' taking the transition to_state and prefixing it with the
  # Order.singular_name.
  def broadcast_event(event, *args)
    options = args.extract_options!

    event_name = if options.delete(:prefix)
                   prefix_name = self.class.singular_name
                   prefix_name.empty? ? event : [prefix_name, event].join('_')
                 else
                   event
                 end

    broadcast_args = options.empty? ? args : args.push(options)

    broadcast(event_name, self, *broadcast_args)
  end

  module ClassMethods
    def singular_name
      respond_to?(:model_name) ? model_name.singular : String(name).downcase
    end
  end
end
