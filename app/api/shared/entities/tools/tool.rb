class Shared::Entities::Tools::Tool < Grape::Entity
  expose :id, :name, :description
  expose :icon, with: Shared::Entities::Tools::ToolIcon
end
