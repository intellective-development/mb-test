class SupplierAPIV2::SettingsEndpoint < BaseAPIV2
  namespace :settings do
    before do
      @working_hours = []
      @settings = {}
    end
    get do
      @working_hours = WorkingHour.all
      @settings[:working_hours] = @working_hours

      present :settings, @settings, with: SupplierAPIV2::Entities::Settings
    end
  end
end
