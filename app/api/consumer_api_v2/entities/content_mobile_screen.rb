class ConsumerAPIV2::Entities::ContentMobileScreen < Grape::Entity
  expose :name, as: :page_name
  expose :content_count
  expose :content do |_instance, _options|
    ConsumerAPIV2::Entities::ContentMobileModule.represent(content, merged_context).reject { |content| content.object.config.nil? || content.send(:value_for, :config).nil? }
  end

  private

  def merged_context
    options[:context][:platform] ||= object.platform
    options[:context]
  end

  def load_content
    @content ||= options[:context][:user_id] ? object.modules.priority_order.logged_in : object.modules.priority_order.logged_out
  end

  def content_count
    load_content.size
  end

  def content
    load_content
  end
end
