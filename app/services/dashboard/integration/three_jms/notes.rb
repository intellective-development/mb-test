module Dashboard
  module Integration
    module ThreeJMS
      class Notes
        def self.add_note(shipment, note, critical = false, asana_tags = [])
          notes_service = Dashboard::Integration::Notes.new('3JMS', RegisteredAccount.three_jms.user.id)
          Rails.logger.info "[3JMS] Adding note to shipment #{shipment.id}"
          notes_service.add_note(shipment, note, critical, [AsanaService::COMMENT_TAG_ID, *asana_tags])
        end
      end
    end
  end
end
