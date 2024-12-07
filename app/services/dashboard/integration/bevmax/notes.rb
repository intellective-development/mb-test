module Dashboard
  module Integration
    module Bevmax
      class Notes
        def self.add_note(shipment, note, critical = false, asana_tags = [])
          notes_service = Dashboard::Integration::Notes.new('BevMax', RegisteredAccount.bevmax.user.id)
          Rails.logger.info "Adding note to shipment #{shipment.id}"
          notes_service.add_note(shipment, note, critical, [AsanaService::COMMENT_TAG_ID, *asana_tags])
        end
      end
    end
  end
end
