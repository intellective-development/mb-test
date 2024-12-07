module MigratingAttributes
  ##
  # This is used to stop breakage when migrations that rename attributes are run. It provides vanilla accessors
  # for regular attribute accessors.
  #
  # = Useage
  # require 'concerns/MigratingAttributes'
  # class Whatever < AR::Base
  #   extend MigratingAttributes
  #   migrate_attribute :this, to: :that, warning: true
  # end
  #
  # 1. deploy the code which references the renamed attributes.
  # 2. wait for all the long running processes to complete.
  # 3. run migrations (which will now move to the new attribute names)
  # 4. remove the above code
  #
  # warning: true will log a warning message with a backtrace when the old attribute name is used.
  #
  # This isn't a silver bullet, it's just for vanilla attributes that haven't been overridden in the model.

  def migrate_attribute(from, to: nil, warning: false)
    raise ArgumentError, 'Required syntax is migrate_attribute(:original, to: :new).' unless from && to

    from = from.to_sym
    to = to.to_sym

    define_migrating_methods(from, to)
    define_migrating_methods(to, from, warning: warning)
  end

  def warn_attribute_reference(primary, alternate)
    logger.warn('#' * 60)
    logger.warn("Attribute #{alternate} is still being referenced. Change references to #{primary}.")
    Rails.backtrace_cleaner.clean(caller(1..-1)).each { |line| logger.warn(line) }
  end

  private

  def define_migrating_methods(primary, alternate, warning: false)
    define_method(alternate) do
      self.class.warn_attribute_reference(primary, alternate) if warning
      if has_attribute?(primary)
        self[primary]
      else
        self[alternate]
      end
    end

    define_method(:"#{alternate}=") do |value|
      self.class.warn_attribute_reference(primary, alternate) if warning
      if has_attribute?(primary)
        self[primary] = value
      else
        self[alternate] = value
      end
    end
  end
end
