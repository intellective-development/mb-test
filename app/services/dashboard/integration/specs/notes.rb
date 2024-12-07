module Dashboard
  module Integration
    module Specs
      class Notes
        def self.add_note(shipment, note, critical = false, asana_tags = [])
          notes_service = Dashboard::Integration::Notes.new("Spec's", RegisteredAccount.specs.user.id)
          notes_service.add_note(shipment, note, critical, [AsanaService::COMMENT_TAG_ID, *asana_tags])
        end
      end
    end
  end
end
