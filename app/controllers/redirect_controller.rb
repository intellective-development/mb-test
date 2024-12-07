class RedirectController < ApplicationController
  before_action :load_utm_params

  def handle_request
    redirect_to redirect_url, status: :moved_permanently
  end

  private

  # Occasionally we want to append UTM tracking parameters onto the end of a
  # URL, these are stored in en.yml and appended here if they exist.
  def load_utm_params
    @utm_params = I18n.t("redirects.#{request.fullpath[1..255]}")
    @utm_params = {} unless @utm_params.is_a?(Hash)
  end

  def redirect_url
    redirect_url = URI.parse(params[:url] || '/')
    query        = URI.encode(params.except(:controller, :action, :url).permit!.to_h.merge(@utm_params).to_query)

    redirect_url.query = query.empty? ? nil : query
    redirect_url.to_s
  end
end
