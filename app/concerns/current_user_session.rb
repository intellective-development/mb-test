module CurrentUserSession
  extend ActiveSupport::Concern

  included do
    helper_method :current_user,
                  :session_cart,
                  :session_supplier,
                  :set_session_supplier,
                  :expire_all_browser_cache

    before_action :secure_session
  end

  def current_user
    @current_user ||= current_registered_account&.user
  end

  def clear_current_user
    @current_user = nil
  end

  def logged_out?
    !current_user
  end

  def secure_session
    cookies[:insecure] = if Rails.env.production?
                           if (request.content_type == 'application/json' || session_cart) && !request.ssl?
                             true
                           else
                             false
                           end
                         else
                           false
                         end
  end

  def session_cart
    return @session_cart if defined?(@session_cart)

    session_cart!
  end

  # use this method if you want to force a SQL query to get the cart.
  def session_cart!
    if cookies.signed[:cart_id]
      @session_cart = Cart.includes(:shopping_cart_items).find_by(id: cookies.signed[:cart_id])
      @session_cart ||= Cart.create(user_id: current_user.try(:id), storefront_id: Storefront::MINIBAR_ID)
    elsif current_user&.current_cart
      @session_cart = current_user.current_cart
    else
      @session_cart = Cart.create(storefront_id: Storefront::MINIBAR_ID)
    end
    @session_cart
  end

  def set_session_supplier(id)
    cookies[:sid] = id
  end

  def session_supplier
    @session_supplier = cookies[:sid] if cookies[:sid]
    @session_supplier
  end

  def session_address
    @session_address = JSON.parse(cookies[:address]) if cookies[:address]
    @session_address
  end

  def expire_all_browser_cache
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma']        = 'no-cache'
    response.headers['Expires']       = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end
end
