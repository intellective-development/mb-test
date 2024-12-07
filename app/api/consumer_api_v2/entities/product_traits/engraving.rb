# frozen_string_literal: true

# ConsumerAPIV2::Entities::ProductTraits::Engraving
#
# Entities for engraving product traits
class ConsumerAPIV2::Entities::ProductTraits::Engraving < Grape::Entity
  expose :engraving_lines, as: :lines
  expose :engraving_lines_character_limit, as: :lines_character_limit
end
