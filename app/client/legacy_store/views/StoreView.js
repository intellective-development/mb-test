import _ from 'lodash';
import alertBoxTpl from 'legacy_store/templates/store/alert_box';
import refreshBoxTpl from 'legacy_store/templates/store/refresh_box';
import { BackboneRXView } from 'shared/utils/backbone_rx';
import { ui_actions } from 'store/business/ui';

Store.StoreView = BackboneRXView.extend({
  el: 'body',
  events: {
    'click #link-email-capture'   : 'launchEmailCapture',
    'click #list-more'            : 'loadAdditionalProducts',
    'click .link-checkout'        : 'linkToCheckout',
    'click .link-home'            : 'linkToMain'
  },
  alertBoxTpl: alertBoxTpl,
  refreshBoxTpl: refreshBoxTpl,
  loadingData: true,
  initialize: function(options){
    window.MiniBarView = this;
    this.$storeLoader = this.$('#store-loader');

    Store.DeliveryAddress           = new Address();
    Store.PickupDetail              = new PickupDetail();
    Store.Suppliers                 = new Suppliers();

    Store.Cart                        = new Cart();
    Store.ProductDetailViewInstance   = new ProductDetailView();
    Store.ProductListView             = new Store.ProductListView();
    Store.CartView                    = new Store.CartView();
    Store.CartShareView               = new Store.CartShareView();
    Store.CheckoutView                = new Store.CheckoutView();
    Store.NavigationBar               = new Store.NavigationBarView(); // needs to be initialized after CheckoutView gets mounted
    Store.GenericContentLayout        = new Store.GenericContentLayoutView();

    this.listenTo(this, 'show_page', this.showPage);
    this.listenTo(Store.Suppliers, 'suppliers:ready', this.ready);
    this.listenTo(Store.Suppliers, 'suppliers:changed', this.ready);
    this.listenTo(Store.Suppliers, 'suppliers:changed', this.suppliersChanged);
    this.listenTo(Store.Suppliers, 'suppliers:changed', this.renderLegalFootnotes);
    this.listenTo(Store.Suppliers, 'load:failed', this.showFatalError);
  },
  showFatalError: function(){
    window.location = '/';
  },
  showAlertBox: function(title, message){
    var alertBox = $('#modal-alert-box').html(this.alertBoxTpl({
      title:    title,
      message:  message
    }));

    alertBox.find('#alertbox-cta').click(function(){
      alertBox.foundation('reveal', 'close');
    });

    alertBox.foundation('reveal', 'open');
    this.scrollToTop();
  },
  showRefreshBox: function(title, message){
    var modal = $('#modal-alert-box').html(this.refreshBoxTpl());

    modal.find('#refreshbox-cta').click(function(e){
      var $this = $(this);
      $this.text('Refreshing...');
      $this.addClass('disabled');
      location.reload(true);
    });

    var view = this;
    _.delay(function(){ //foundation cant handle simultaneous calls, ie when the 401 status code handler fires
      if (!modal.hasClass('open')){
        modal.foundation('reveal', 'open');
        view.scrollToTop();
      }
    });
  },
  suppliersChanged: function(){
    this.$storeLoader.hide();
  },
  renderLegalFootnotes: function(){
    $('#footnote-nyc').remove();
    if(Store.Suppliers.length > 1){ // FIXME: This is not a good check, doesn't handle promo suppliers
      $('.footnote', '#footer').first().after('<p class="footnote" id="footnote-nyc">Wine & Spirits Sold Separately from Beer & Grocery in NY State.</p>');
    }
  },
  changeAddress: function(){
    this.storeDispatch(ui_actions.showDeliveryInfoModal());
  },

  ready: function(){
    if (!this.loadingData) return null;

    this.loadingData = false;
    this.listenTo(window.Minibar, 'route', this.scrollToTop);
    this.trigger('ready');
  },

  scrollToTop: function(){
    window.scrollTo(0,0);
  },

  showPage: function(show_pages){
    var show_pages = _.isArray(show_pages) ? show_pages : [show_pages],
        all_pages = ['main', 'products', 'cocktails', 'product_detail', 'cart', 'cart_share', 'checkout', 'generic_content_layout'],
        hide_pages = _.difference(all_pages, show_pages),
        view = this;
    _.each(hide_pages, function(page){
      view.trigger('hide:' + page)
    });
    this.$storeLoader.hide();
    _.each(show_pages, function(page){
      view.trigger('show:' + page);
    });
  },

  showLoader: function(){
    this.$storeLoader.fadeIn(Constants.screen_fade_in_speed);
  },
  hideLoader: function(){
    this.$storeLoader.hide();
  },

  linkToMain: function(){
    window.Minibar.navigate('', {trigger: true});
    return false;
  },

  linkToCart: function(){
    window.Minibar.navigate('cart', {trigger: true});
    return false;
  },

  linkToCheckout: function(){
    window.Minibar.navigate('checkout', {trigger: true});
    return false;
  },
  navigateToCart: function(){
    this.trigger('show_page', 'cart');
  },
  navigateToCartShare: function(){
    this.trigger('show_page', 'cart_share');
  },
  navigateToCheckout: function(){
    this.trigger('show_page', 'checkout');

    if (Store.Order.completed()){
      // This will refresh the page if you get to checkout and you've already checked out.
      // TODO LD: better solution. This is a nuke it from orbit approach to ensure there's
      // nothing hanging around in the models/views that shouldn't be there, but ideally we should just
      // reset all that when we actually complete the order.
      document.location.reload();
    }
    Store.CheckoutView.render();
  },
  navigateToProductDetail: function(permalink, variant_permalink){
    Store.ProductDetailViewInstance.render(permalink, variant_permalink);
    this.trigger('show_page', 'product_detail');
  },
  navigateToMain: function(){
    this.trigger('show_page', 'main');
  },
  navigateToProductList: function(){
    this.scrollToTop();
    this.trigger('show_page', 'products');
  },
  navigateToGenericContentLayout: function(content_layout_name: string){
    Store.GenericContentLayout = new Store.GenericContentLayoutView({ content_layout_name });
    this.trigger('show_page', 'generic_content_layout');
  },
  navigateToCocktails: function(){
    this.trigger('show_page', 'cocktails');
  }
});

export default Store.StoreView;

//TODO: remove! use real dependencies!
window.Store.StoreView = Store.StoreView;
