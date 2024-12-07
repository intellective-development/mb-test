# The content controller handles our static content pages - typically they have
# limited interaction with database models, do not require authentication and
# are cacheable to a large extent.
#
# They live in `app/views/content`` and individual pages are defined in `routes.rb`.
#
# When defining a new content route, we support the following parameters:
#
# * `page`           (string, required)  The name of the content template to be loaded.
# * `layout`         (string, optional)  Overrides the default layout used when rendering.
# * `redirect_path`  (string, optional)  Redirects the customer to the given path if a
#                                        `session_address` value is present.
#

class ContentController < ApplicationController
  respond_to :json, :html, :js
  layout 'minibar'

  def handle_request
    if should_redirect?
      redirect_to params[:redirect_path]
    else
      render "/content/#{params[:page]}", layout: params[:layout] || 'minibar'
    end
  rescue ActionView::MissingTemplate
    not_found
  end

  def not_found
    render status: :not_found, file: Rails.root.join('public', '404.html').to_s, layout: false
  end

  private

  def should_redirect?
    params[:redirect_path] && session_supplier && session_address
  end
end
