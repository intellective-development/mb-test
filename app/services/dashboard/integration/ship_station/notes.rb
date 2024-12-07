# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      # Notes is a class that implements the NotesInterface for ShipStation Integrations
      class Notes
        def self.add_note(shipment, note, critical: false, asana_tags: [])
          notes_service = Dashboard::Integration::Notes.new('ShipStation', RegisteredAccount.ship_station.user.id)
          Rails.logger.info "[ShipStation] Adding note to shipment #{shipment.id}"
          notes_service.add_note(shipment, note, critical, [AsanaService::COMMENT_TAG_ID, *asana_tags])
        end
      end
    end
  end
end
