class AdminAPIV1::DealsEndpoint < BaseAPIV1
  namespace :deals do
    desc 'Creates or updates a deal'
    post :publish do
      # In deals.minibardelivery.com we manage deals, we need this copy because we do
      # some queries in MB + we fill ES with deals related to variants, pgs and products
      # TODO: Use deals.minibardelivery.com to manage the records HERE, so we only have one
      # table for deals (this one) and deals is just the UI to CRUD it.
      deal = Deal.find_or_initialize_by(id: params[:id])
      deal.user = RegisteredAccount.where(email: params.delete(:user_email)).first.user
      deal.assign_attributes(params)
      if deal.save
        status 201
        present :success, true
      else
        error!(deal.errors.full_messages, 400)
      end
    end
  end
end
