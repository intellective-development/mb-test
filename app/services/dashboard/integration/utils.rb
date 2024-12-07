module Dashboard
  module Integration
    class Utils
      def self.parse_resource(integration_name, value)
        value = value.body unless value&.body.nil?

        # Try to parse as a JSON
        if value.is_a? String
          begin
            return JSON.parse(value)
          rescue StandardError => e
            # proceed further
          end
        end

        # Stringify OpenStruct
        return value.to_s if value.is_a? OpenStruct

        value
      rescue StandardError => e
        Rails.logger.error "[#{integration_name}] Error parsing resource value for error reporting: #{value}"

        nil
      end
    end
  end
end
