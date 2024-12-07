module Dashboard
  module Integration
    module SevenEleven
      class Notes
        def self.add_note(shipment, note, critical = false, asana_tags = [])
          notes_service = Dashboard::Integration::Notes.new('7NOW', RegisteredAccount.seven_eleven.user.id)
          notes_service.add_note(shipment, note, critical, [AsanaService::SEVEN_ELEVEN_GENERAL_TAG, *asana_tags])
        end
      end
    end
  end
end
