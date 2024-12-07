# Admin::CocktailsController
#
# Cocktails Controller
class Admin::CocktailsController < Admin::BaseController
  def index
    params[:query] ||= ''
    @cocktails = Cocktail.includes(:brand, :tools, :ingredients)
                         .where('lower(cocktails.name) LIKE ?', "%#{params[:query].downcase}%")
                         .order(:name)
                         .page(pagination_page)
                         .per(25)
  end
end
