# Provides a relatively clean way to optionally disable all callbacks in the application
# and selectively turn them back on. The obvious place to do this is in the test suite.
#
# Create a callback class for your class
#
#    class MyModel < AR::Base
#      class Callbacks < OptionalCallbacks::Base
#        before_save(object)
#          puts "MyModel: #{object.object_id}"
#        end
#      end
#
#      OptionalCallbacks = Callbacks.new
#
#      before_save OptionalCallbacks
#      before_save :never_disabled
#    end
#
# By default OptionalCallbacks are not disabled. You can disable them globally;
#
#    OptionalCallbacks::Base.disabled = true
#
#    obj = MyModel.new
#    obj.save # =>
#    MyModel::OptionalCallbacks.disabled = false
#    obj.save # => MyModel: 70093033737060
#    MyModel::OptionalCallbacks.disabled = true
#    obj.save # =>
#
# OptionalCallbacks makes no attempt to protect you from misspelling a callback
# or creating a callback that sits outside of the standard AR lifecycle.
#
# If using this in test, which is what it's primary purpose is, always ensure that
# you reset the disabled flag on exactly the class you used, an around is a good
# way to achieve that.
#
#    around do |example|
#      MyModel::OptionalCallbacks.disabled = false
#      example.run
#      MyModel::OptionalCallbacks.disabled = true
#    end
#
module OptionalCallbacks
  class Base
    class_attribute :disabled

    def self.method_missing(method_name, *args, &block)
      if recognized_callback?(method_name)
        call_if_enabled = ->(object) { disabled? || block.call(object) }
        define_method(method_name, &call_if_enabled)
      else
        super
      end
    end

    def self.respond_to_missing?(method_name, include_private = false)
      recognized_callback?(method_name) || super
    end

    def self.recognized_callback?(method_name)
      /^(after|before|around)_(save|create|update|destroy)$/ =~ method_name ||
        /^after_(initialize|find|touch|commit|rollback)$/ =~ method_name ||
        /^(before|after)_validation$/ =~ method_name
    end
  end
end
