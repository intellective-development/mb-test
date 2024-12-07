class ConsumerAPIV2::Entities::EngravingOption < Grape::Entity
  expose :type, proc: lambda { |_instance, _options|
    Variant.options_types[:engraving]
  }

  expose :line1
  expose :line2
  expose :line3
  expose :line4
end
