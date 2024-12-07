class Admin::Config::BaseController < Admin::BaseController
  before_action :verify_super_admin # ONLY SUPER ADMINS should see this
end
