module Admin::Content::LandingPagesHelper
  def landing_page_url(permalink)
    "/go/#{permalink}"
  end
end
