class LandingPagesController < ApplicationController
  def show
    @landing_page = LandingPage.find_by(permalink: params[:permalink])
    if @landing_page
      @content = @landing_page.content
      @subheadline = @content.subheadline_2 ? "#{@content.subheadline_1}<br />#{@content.subheadline_2}" : @content.subheadline_1
      @legal = @content.legal
    else
      Sentry.capture_message("Invalid Landing Page: #{params[:permalink]}")
      redirect_to root_path
    end
  end
end
