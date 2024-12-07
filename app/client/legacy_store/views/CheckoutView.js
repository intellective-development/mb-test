import _ from 'lodash';
import * as React from 'react';
import renderComponentRoot from 'shared/utils/render_component_root';
import I18n from 'store/localization';
import checkoutEmptyTpl from 'legacy_store/templates/store/checkout_empty';
import checkoutOrderDetailsTpl from 'legacy_store/templates/store/checkout_order_details';
import checkoutThankYouTpl from 'legacy_store/templates/store/checkout_thankyou';
import checkoutTpl from 'legacy_store/templates/store/checkout';
import moment from 'moment';
import { BackboneRXView } from 'shared/utils/backbone_rx';
import { mobileUAChecks as isMobile } from 'shared/utils/is_mobile';
import { dispatchAction } from 'shared/dispatcher';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import { hasShopRunnerToken } from 'client/shared/utils/shop_runner';
import { cart_item_helpers, cart_item_selectors, cart_item_actions } from '../../store/business/cart_item/index';
import { MBTooltip } from '../../store/views/elements';

Store.CheckoutView = BackboneRXView.extend({
  el: '#checkout-detail',
  events: {
    'change #delivery_notes'                    : 'setDeliveryNotes',
    'change #gift_message'                      : 'setGiftOptions',
    'change #gift_recipient'                    : 'setGiftOptions',
    'change #gift_recipient_phone'              : 'setGiftOptions',
    'change #is_gift'                           : 'toggleGift',
    'change #replenishment_interval'            : 'setReplenishmentOptions',
    'change #enable_replenishment'              : 'setReplenishmentOptions',
    'click .add-billing'                        : 'renderPaymentProfile',
    'click .edit-address'                       : 'renderDeliveryAddress',
    'click .edit-pickup-details'                : 'renderPickupDetail',
    'click #button-apply-promo'                 : 'addPromoCode',
    'click #edit-tip'                           : 'activateTipField',
    'click #edit-billing'                       : 'renderChoosePaymentProfile',
    'dblclick #tip'                             : 'activateTipField',
    'keyup #promo'                              : 'enablePromoCode',
    'keyup #gift_message'                       : 'countGiftCardCharacters',
    'click #button-order-submit'                : 'submitOrder',
  },
  checkoutEmptyTpl: checkoutEmptyTpl,
  checkoutOrderDetailsTpl: checkoutOrderDetailsTpl,
  checkoutThankYouTpl: checkoutThankYouTpl,
  checkoutTpl: checkoutTpl,
  editingTip: false,
  submit_attempted: false,
  current_view: false,
  shipment_view: [],
  tracked: false,
  shouldRender: false,
  trackedSteps: [],
  initialize: function(options){
    this.logInView = new Store.LogInView();
    Store.Order = new Order();
    Store.Order.setDefaults();
    Store.Order.createOrder();
    this.cart_loaded = false;

    this.listenTo(Store.Cart, 'cart:change', this.render); // while cart is changing
    this.listenTo(Store.Order, 'change:tip', this.validateOrder);
    this.listenTo(Store.Order, 'order:validated', this.renderOrderSubmit);
    this.listenTo(Store.Order, 'order:syncing', this.renderOrderSubmit);
    this.listenTo(Store.Order, 'order:scheduled', this.renderOrderSubmit);
    this.listenTo(Store.Order, 'change:promo_code', this.validateOrder);
    this.listenTo(Store.Order, 'change:payment_profile_id', this.render);
    this.listenTo(Store.Order, 'change:payment_profile_id', this.validateOrder);
    this.listenTo(Store.Order, 'change:shipping_address_id', this.validateOrder);
    this.listenTo(Store.Order, 'change:pickup_detail_id', this.validateOrder);
    this.listenTo(this, 'render', this.validateOrder);
    this.listenTo(Store.Order, 'order:charge:success', this.render);
    this.listenTo(Store.Order, 'order:charge:success', this.resetCart);
    this.listenTo(Store.Order, 'order:charge:error', this.handleErrors);
    this.listenTo(Store.Order, 'order:invalid', this.handleErrors);
    this.listenTo(User, 'new_user_changed', this.render);
    this.listenTo(User, 'login:success', this.handleUserLogin);
    this.listenTo(User, 'user:created', this.handleUserLogin);
    this.listenTo(User, 'user:payment_profile:added', this.selectBilling);
    this.listenTo(this, 'payment_profile:cancel', this.render);
    this.listenTo(this, 'payment_profile:select', this.render);
    this.listenTo(Store.DeliveryAddress, 'delivery_address:associated', this.render);
    this.listenTo(Store.PickupDetail, 'pickup_detail:saved', this.render);

    Store.Order.updateItems();
    this.listenTo(MiniBarView, 'show:checkout', this.showElement);
    this.listenTo(MiniBarView, 'hide:checkout', this.hideElement);
  },

  initializeShipmentView(){
    this.shipment_view = new Store.CheckoutShipmentView();
  },

  handleUserLogin(){
    // TODO: this should no longer be necessary.
    // Originally, our Registration endpoint would log in users if an account already existed and the password provided was correct.
    // This small hack was necessary to update the order with a payment profile ID in those cases.
    Store.Order.setDefaults();
    this.render();
  },

  handleErrors: function(e){
    this.renderOrderSubmit();

    const default_description = 'We were unable to process your order, please try again later.';
    let description, name;

    if(e.description){
      name = e.description.name;
      description = e.description.message;
    } else {
      name = e.name;
      description = e.message || default_description;
    }

    if(name !== undefined){ // If there's a name, we trust the message
      Raven.captureMessage('Checkout Error: ' + name, { extras: { message: description }});

      switch(name){
        case 'LowOrderSubTotal':
          if (this.current_view) MiniBarView.showAlertBox('Minimum Order Value Not Met', description);
          break;
        case 'ValidationError':
          switch(true) {
            case description.toLowerCase().indexOf('gift') > -1:
              if (this.current_view) MiniBarView.showAlertBox('Gift Information Missing', 'We require the name and contact number for the gift recipient.');
              $('#gift_message').addClass('error');
              $('#gift_recipient_phone').addClass('error');
              $('#gift_recipient').addClass('error');
              break;
            default:
              if (this.current_view) MiniBarView.showAlertBox('Sorry, An Error Occured', description);
              break;
          }
          break;
        case 'InvalidPromoCode':
          this.$('#promo').val('');
          this.$('#promo-errors').html(description).fadeIn();
          break;
        case 'SchedulingIncomplete':  // from the internal validations
        case 'SchedulingMissing': // from the internal validations
          this.errorPanel('Please schedule your order below');
          break;
        default:
          if (this.current_view) MiniBarView.showAlertBox('Sorry, An Error Occured', description);
          break;
        }
    } else { //Otherwise, we display a default
      let message = default_description;
      if(description === 'Your card has been declined. Please select another card or try again later.'){
        message = description;
      }
      MiniBarView.showAlertBox('Sorry, An Error Occured', message);
      Raven.captureMessage('Unhandled Checkout Error: ' + e);
    }
  },
  errorPanel: function(message){
    if (!this.submit_attempted) return false;

    const $button = $('#button-order-submit'),
        $error_panel = $('.panel.error');
    $button.html('Place Order');
    $error_panel.find('p').html(message);
    $error_panel.find('p').show();
    $error_panel.fadeIn('fast');
  },
  validateOrder: function(){
    Store.Order.updateOrder();
  },
  submitOrder: function(model){
    if(!this.checkBirthdate()) {
      return false;
    }

    const $button = $('#button-order-submit'),
        $error_panel = $('.panel.error');

    if (!Store.Order.isSyncing){
      $error_panel.fadeOut('fast');
      this.submit_attempted = true;
      this.trigger('checkout:submit_attempted', this.submit_attempted);
      $button.html('Processing...');
    }
    Store.Order.finalize(); // event listeners handle re-rendering if needed
    return false;
  },
  toggleGift: function(e){
    const is_gift = this.$('#is_gift').is(':checked'),
      messageField = this.$('#gift-message');

    Store.Order.set('is_gift', is_gift);

    if(is_gift){
      messageField.removeClass('hidden').slideDown();
      Store.Order.set('message', this.$('#gift_message').val()); //unclear why this is here
    } else {
      messageField.slideUp();
      this.$('#gift_message').val('');
      this.$('#gift_recipient_phone').val('');
      this.$('#gift_recipient').val('');
      Store.Order.clearGiftOptions();
    }
  },
  countGiftCardCharacters: function() {
    let x = $('#gift_message').val(),
        newLines = x.match(/(\r\n|\n|\r)/g),
        addition = 0,
        remaining = (200 - $('#gift_message').val().length);

    if (newLines !== null) {
        addition = newLines.length;
    }

    this.$('#gift-message_chars-left').text(remaining);
  },
  setReplenishmentOptions: function(){
    Store.Order.set({
      'replenishment' : {
        'enabled' : this.$('#enable_replenishment').prop('checked'),
        'interval' : parseInt(this.$('#replenishment_interval').val()) * 7
      }
    });
  },
  setGiftOptions: function(){
    $('#gift-message').children().removeClass('error');
    Store.Order.set({
      'gift_options': {
        'message'         : this.$('#gift_message').val(),
        'recipient_name'  : this.$('#gift_recipient').val(),
        'recipient_phone' : this.$('#gift_recipient_phone').val()
      }
    });
  },
  setDeliveryNotes: function(){
    Store.Order.set('delivery_notes', this.$('#delivery_notes').val());
  },
  selectBilling: function(e){
    Store.Order.set('payment_profile_id', e.payment_profile_id);
  },
  trackCheckoutStep: function(step_name, option){
    // We only want to track each checkout step once during the lifetime of this
    // view, rather than each time it is rendered.
    if(!_.includes(this.trackedSteps, step_name)){
      this.trackedSteps.push(step_name);

      dispatchAction({actionType: 'track:checkout_step', step_name: step_name, option: option });
    }
  },
  renderOrderSubmit: function(e){
    const year = (new Date()).getFullYear();
    const startYear = year - 110;
    this.birthdateRequired = Store.Suppliers.models.filter(supplier => supplier.attributes.birthdate_required).length > 0;

    this.$('#order-details').html(this.checkoutOrderDetailsTpl({
      allow_tip:           typeof(Store.Order.get('tip')) !== 'undefined',
      coupon_amount:       Store.Order.get('coupon_amount') === '0.00' ? false : Store.Order.get('coupon_amount'),
      deal_amount:         Store.Order.get('deal_amount') === '0.00' ? false : Store.Order.get('deal_amount'),
      invalid:             (!Store.Order.isValid() && this.submit_attempted), // gives first attempt
      invalid_or_updating: (!Store.Order.isValid() && this.submit_attempted) || Store.Order.isSyncing,
      promo_code:          Store.Order.get('promo_code'),
      qualified_deals:     Store.Order.get('qualified_deals'),
      shipping_charges:    Store.Order.get('shipping_charges'),
      sub_total:           Store.Order.get('sub_total'),
      taxed_amount:        Store.Order.get('taxed_amount'),
      tip:                 Store.Order.get('tip'),
      total:               Store.Order.get('total_amount'),
      updating:            Store.Order.isSyncing,
      days:                this.getRange(1, 31),
      months:              this.getRange(1, 12),
      years:               this.getRange(startYear, year),
      birthdate_required:  this.birthdateRequired,
      shoprunner:          hasShopRunnerToken()
    }));

    if(this.birthdateRequired && document.getElementById('birthdate_required_info')) {
      renderComponentRoot(
        React.createElement(MBTooltip, {
          default_orientation: 'bottom',
          tooltip_text: I18n.t('ui.body.cart.birthdate_required')
        }),
        document.getElementById('birthdate_required_info')
      );
    }
    const monthEle = this.$("#monthOfBirth");
    if(this.birthMonth) {
      monthEle.val(this.birthMonth);
    }
    monthEle.on('change', () => {
      this.birthMonth = parseInt(monthEle.val());
      this.checkBirthdate();
    });
    const dayEle = this.$("#dayOfBirth");
    if(this.birthDay) {
      dayEle.val(this.birthDay);
    }
    dayEle.on('change', () => {
      this.birthDay = parseInt(dayEle.val());
      this.checkBirthdate();
    });
    const yearEle = this.$("#yearOfBirth");
    if(this.birthYear) {
      yearEle.val(this.birthYear);
    }
    yearEle.on('change', () => {
      this.birthYear = parseInt(yearEle.val());
      this.checkBirthdate();
    });
    this.checkBirthdate();
  },
  checkBirthdate() {
    if(!this.birthdateRequired) {
      return true;
    }
    const birthdate = moment();
    birthdate.year(this.birthYear);
    birthdate.month(this.birthMonth);
    birthdate.day(this.birthDay);
    const $button = $('#button-order-submit');
    if(this.birthDay && this.birthMonth && this.birthYear && birthdate && birthdate.isValid() && moment().diff(birthdate, 'year') >= 21) {
      Store.Order.set('birthdate', birthdate.toISOString());
      $button.removeAttr('disabled');
      return true;
    }
    $button.attr('disabled','disabled');
    return false;
  },
  getRange: function(start, end) {
    return Array.from({length: ((end + 1) - start)}, (v, k) => k + start)
  },
  renderThankYou: function(){
    this.setBreadcrumb('hidden');
    this.trackCheckoutStep('thank_you', '');

    this.trackScreen("checkout_submit");
    if (this.current_view) MiniBarView.scrollToTop();

    this.trackedSteps = [];

    this.$el.html(this.checkoutThankYouTpl({
      order: Store.Order.toJSON(),
      referral_code: User.referralCode(),
      referral_reward: Data.referral_reward,
      next_steps: thankYouNextSteps(Store.Order.getShipments())
    }));
  },
  renderPaymentProfile: function(){
    this.setBreadcrumb('payment');
    this.trackCheckoutStep('add_payment', 'new');

    if (this.current_view) MiniBarView.scrollToTop();
    this.CheckoutPaymentProfileView = new CheckoutPaymentProfileView();
  },
  renderChoosePaymentProfile: function(){
    this.setBreadcrumb('payment');
    this.trackCheckoutStep('add_payment', 'select');

    if (this.current_view) MiniBarView.scrollToTop();
    this.CheckoutChoosePaymentProfileView = new CheckoutChoosePaymentProfileView();
  },
  renderDeliveryAddress: function(){
    this.setBreadcrumb('delivery');
    this.trackCheckoutStep('confirm_address', 'new');

    if (this.current_view) MiniBarView.scrollToTop();

    if (this.CheckoutShippingAddressView){ //don't double create
      this.CheckoutShippingAddressView.initialize();
    } else {
      this.CheckoutShippingAddressView = new CheckoutShippingAddressView();
    }
  },
  renderPickupDetail: function(){
    this.setBreadcrumb('delivery');
    this.trackCheckoutStep('pickup_detail', 'new');

    if (this.current_view) MiniBarView.scrollToTop();

    if (this.CheckoutPickupDetailView){ //don't double create
      this.CheckoutPickupDetailView.initialize();
    } else {
      this.CheckoutPickupDetailView = new CheckoutPickupDetailView();
    }
  },
  renderUserProfile: function(){
    this.setBreadcrumb('sign-in');
    this.trackCheckoutStep('authentication', 'new_user');

    if (this.current_view) MiniBarView.scrollToTop();
    this.UserProfileView = new CheckoutNewUserView();
  },
  renderLogin: function(){
    this.trackCheckoutStep('authentication', 'log_in');
    this.setBreadcrumb('sign-in');
    this.logInView.render();
  },
  renderCheckout: function(){
    this.setBreadcrumb('checkout');
    this.initializeShipmentView();
    this.trackCheckoutStep('confirmation', '');

    if (this.current_view) MiniBarView.scrollToTop();
    const gift_options = Store.Order.get('gift_options') || {recipient_name: '', recipient_phone: '', message: ''};

    let delivery_info = {};
    if (Store.Order.hasAddressShipments()){
      delivery_info = {
        ...delivery_info,
        shipping_address: {
          ...Store.DeliveryAddress.toJSON(),
          formatted_phone: Store.DeliveryAddress.formattedPhoneNumber()
        },
        isCA: Store.DeliveryAddress && Store.DeliveryAddress.toJSON().state === 'CA'
      };
    }
    if (Store.Order.hasPickupShipments()){
      delivery_info = {
        ...delivery_info,
        pickup_detail: {
          ...Store.PickupDetail.toJSON(),
          formatted_phone: Store.PickupDetail.formattedPhoneNumber()
        }
      };
    }
    const selected_payment_profile = _.find(User.get('payment_profiles'), ({id}) => id === Store.Order.get('payment_profile_id'));
    const payment_profile = selected_payment_profile || User.defaultPaymentProfile();

    this.$el.html(this.checkoutTpl({
      ...delivery_info,
      payment_profile,
      promo_code: Store.Order.get('promo_code'),
      delivery_notes: Store.Order.get('delivery_notes'),
      is_gift: Store.Order.get('is_gift'),
      gift_recipient: gift_options.recipient_name,
      gift_recipient_phone: gift_options.recipient_phone,
      gift_message: gift_options.message,
      replenishment: Store.Order.get('replenishment'),
      replenishment_interval: Store.Order.get('replenishment_interval'),
      subtotal: Store.Order.get('sub_total'),
      has_multiple_payment_profiles: User.get('payment_profiles').length > 1 ? true : false
    }));
    this.toggleGift();
    Store.Order.updateOrder(); //why is this happening here?

    if(!isMobile.any()){
      this.$('#order-details-container').scrollToFixed({
        limit: 400,
        unfixed: function() { $(this).css({ left: '15px', top: '265px' }); },
        zIndex: 999
      });
    }

    //render order items panel
    this.shipment_view.setElement($('#checkout-shipment'));
    this.shipment_view.render();
  },
  render: function(){
    if(!this.shouldRender) return;

    Store.Order.updateItems();

    if(Store.Order.completed()){
      this.renderThankYou();
    } else {
      this.trackCheckoutStep('initiate', 'new_user');

      if(cart_item_selectors.getAllCartItemIds(this.storeGetState()).length > 0){
        if(User.loggedIn()){
          this.trackCheckoutStep('authentication', 'skipped');

          if (Store.Order.addressMissing()){
            this.renderDeliveryAddress();
          } else {
            this.trackCheckoutStep('confirm_address', 'skipped');

            if (Store.Order.pickupMissing()){
              this.renderPickupDetail();
            } else {
              this.trackCheckoutStep('pickup_detail', 'skipped');

              if (User.defaultPaymentProfile() === undefined){
                this.renderPaymentProfile();
              } else {
                this.trackCheckoutStep('add_payment', 'skipped');
                this.renderCheckout();
              }
            }
          }
        } else {
          if(User.newUser){
            this.renderUserProfile();
          } else {
            this.renderLogin();
          }
        }
      } else {
        this.$el.html(this.checkoutEmptyTpl());
      }
    }

    this.renderOrderSubmit();
    return this;
  },
  setBreadcrumb: function(to_state){
    this.view_state = to_state;
    this.trigger('checkout_breadcrumb:view_state');
  },
  viewState: function(){
    return this.view_state;
  },
  enablePromoCode: function(){
    const $input = this.$('#promo'),
       $button = this.$('#button-apply-promo');

    if($input.val() === '') {
      $button.attr('disabled','disabled');
    } else {
      $button.removeAttr('disabled');
    }
  },
  addPromoCode: function(){
    var $input = this.$('#promo');

    this.$('#promo-errors').fadeOut();

    if($input.val() !== ''){
      this.listenToOnce(Store.Order, 'order:promo:valid', function(e){
        if(e.promo_code){
          $('#promo-errors').removeClass('error').html('Promo code applied').fadeIn();
        }
      });
      Store.Order.setPromoCode($input.val());
    }
  },
  activateTipField: function(){
    const $input = $('#tip'),
       $button = $('#edit-tip'),
          view = this;

    $button.html('Save')
           .unbind('click')
           .click(view.deactivateTipField);

    $input.removeClass('inline')
          .val('')
          .keyup(function(e){
            var code = e.which;
            if(code==13) e.preventDefault();
            if(code==32||code==13||code==188||code==186){
              view.deactivateTipField();
            }
          })
          .focus()
          .blur(view.deactivateTipField);
    view.editingTip = true;
  },
  deactivateTipField: function(){
    const $input = $('#tip'),
       $button = $('#edit-tip'),
          view = this;

    $input.addClass('inline').unbind('keyup');
    $button.html('Edit')
           .unbind('click')
           .click(view.activateTipField);

    if(isNaN(parseFloat($input.val()))){
      $input.val(Store.Order.get('tip'));
    } else {
      Store.Order.setTip(parseFloat($input.val()));
    }

    view.editingTip = false;
  },
  trackView: function(){
    if (!this.tracked){
      this.trackScreen('checkout');
      this.tracked = true;
    }
  },
  showElement: function(){
    this.shouldRender = true;
    this.trackView();

    Store.Order.activate();
    this.current_view = true;
    this.$el.fadeIn(Constants.screen_fade_in_speed);
  },
  resetCart: function(){
    this.storeDispatch(cart_item_actions.deleteCart())
  },
  hideElement: function(){
    this.shouldRender = false;

    Store.Order.deactivate();
    this.current_view = false;
    this.$el.hide();
  }
});

const thankYouNextSteps = (shipments) => {
  const has_shipped = shipment_helpers.hasShippedShipments(shipments);
  const has_pickup = shipment_helpers.hasPickupShipments(shipments);
  const base_message = I18n.t('ui.body.checkout_complete.next_steps_base');

  let message;
  if (has_shipped && has_pickup){
    message = `${base_message} ${I18n.t('ui.body.checkout_complete.next_steps_shipped_and_pickup')}`;
  } else if (has_shipped){
    message = `${base_message} ${I18n.t('ui.body.checkout_complete.next_steps_shipped')}`;
  } else if (has_pickup){
    message = `${base_message} ${I18n.t('ui.body.checkout_complete.next_steps_pickup')}`;
  } else {
    message = base_message;
  }

  return message;
};

export default Store.CheckoutView;

//TODO: remove! use real dependencies!
window.Store.CheckoutView = Store.CheckoutView;
