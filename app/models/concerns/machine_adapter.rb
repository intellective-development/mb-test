# Include this module to get an easy setup of Statesman in a class. This module adds the
# class method statesman_machine for defining the transition class and the state machine class.
#
# @example
#   statesman_machine machine_class: Order::OrderStateMachine, transition_class: OrderTransition
#
# This in turn adds the class methods, machine_class, transition_class and initial_state
# which are used internally by statesman or to set up statesman.
#
# Additionally statesman_machine adds the following methods to the including model
#
# * state_machine        instantiates and caches the machine for this instance.
# * broadcast_event      wraps Wisper::Publisher#broadcast so the state machine can broadcast events
#                        in transitions.
# * allowed_transitions  delegated to state_machine above.
# * can_transition_to?   delegated to state_machine above.
# * transition_to        delegated to state_machine above.
# * transition_to!       delegated to state_machine above.
# * current_state        delegated to state_machine above.
#
# See the specs for examples of how to use this adapter.
module MachineAdapter
  def self.included(base)
    base.include(WisperAdapter) unless base.included_modules.include?(WisperAdapter)
    base.extend(ClassMethods)
  end

  def state_machine
    @state_machine ||= machine_class.new(self, transition_class: transition_class)
  end

  module ClassMethods
    def statesman_machine(machine_class:, transition_class:)
      module_functions = Module.new do
        define_method(:machine_class) { machine_class }
        define_method(:transition_class) { transition_class }
      end

      include(module_functions)
      extend(module_functions)

      define_singleton_method(:initial_state) { machine_class.initial_state }
      private_class_method :initial_state

      class_exec do
        delegate :allowed_transitions, :can_transition_to?, :transition_to, :transition_to!,
                 :current_state, :trigger, :trigger!, :in_state?, to: :state_machine

        machine_class.states.each do |state|
          define_method("#{state}?") { String(current_state(force_reload: true)) == String(state) }
        end

        machine_class.events.each_key do |event| # rubocop:disable Style/MultilineIfModifier
          define_method(event) { state_machine.trigger(event) }
          define_method("#{event}!") { state_machine.trigger!(event) }
        end if machine_class.respond_to?(:events)
      end
    end
  end
end
