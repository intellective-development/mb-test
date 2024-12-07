class ConsumerAPIV2::Entities::AutocompleteResult < Grape::Entity
  expose :type
  expose :id
  expose :name
  expose :permalink
  expose :sponsored
  expose :thumb_url
  expose :image_url

  private

  def id
    object[:result][:id]
  end

  def name
    if object[:type] == :category
      object[:result].name_list.reverse.join(' - ')
    else
      object[:result][:name]
    end
  end

  def sponsored
    object[:type] == :sponsored_product
  end

  def thumb_url
    object[:type] == :sponsored_product && object[:result][:thumb_url] || ''
  end

  def image_url
    image_style =
      case options[:platform]
      when 'ios', 'iphone', 'ipad', 'ipod', 'android'
        :ios_product
      else
        :product
      end
    image_url = ''
    if object[:type] == :sponsored_product
      image_url = image_style == :ios_product ? object[:result]['image_url_mobile'] : object[:result]['image_url_web']
    end
    image_url
  end

  def type
    if object[:type] == :sponsored_product
      :product
    else
      object[:type]
    end
  end

  def permalink
    if object[:type] == :search
      object[:result][:name]
    elsif object[:result].respond_to? :deep_permalink
      object[:result].deep_permalink
    else
      object[:result][:permalink]
    end
  end
end
