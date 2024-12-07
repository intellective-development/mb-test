class ConsumerAPIV2::Entities::MobileHomeScreenModule < Grape::Entity
  expose :module_type
  expose :internal_name
  expose :priority, as: :position
  expose :config

  private

  def config
    object.send("generate_#{object.module_type}_config".to_sym, options)
  end
end
