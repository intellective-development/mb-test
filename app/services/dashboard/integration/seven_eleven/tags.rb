module Dashboard
  module Integration
    module SevenEleven
      module Tags
        module TagsList
          SUCCESSFUL = '[7NOW]shipment_successfully_placed'.freeze
          CANCELLATION_ISSUE = '[7NOW]problem_when_cancelling_shipment'.freeze
          DEFINED_ISSUE = '[7NOW]shipment_with_error_'.freeze
          UNDEFINED_ISSUE = '[7NOW]shipment_with_undefined_issue'.freeze
        end

        class TagsHelper
          def self.add_tag_with_code(shipment, error_code)
            if error_code.present?
              new_tag = TagsList::DEFINED_ISSUE + error_code
              shipment.tag_list.add(new_tag)
            else
              shipment.tag_list.add(TagsList::UNDEFINED_ISSUE)
            end
          end

          def self.add_tag(shipment, tag)
            shipment.tag_list.add(tag)
          end
        end
      end
    end
  end
end
