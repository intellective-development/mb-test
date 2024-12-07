import _ from 'lodash';
import Rx from 'rxjs';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { BackboneRXModel, toObjectStream } from 'shared/utils/backbone_rx';
import { actionStream } from 'shared/dispatcher';
import {
  getPromoCode as getPromoCodeFromStorage,
  removePromoCode as removePromoCodeFromStorage
} from 'shared/promo_code_storage';
import { order_helpers } from 'store/business/order';
import { cart_item_selectors } from 'store/business/cart_item';
import { supplier_selectors } from 'store/business/supplier';
import * as shipment_helpers from './Shipment';

const { getOrderShipments } = order_helpers;
const { validateShipment } = shipment_helpers;

const model_stream = new Rx.BehaviorSubject(null);

// action creators
export const toggleGiftOrder = (is_gift) => ({
  actionType: 'ORDER_TOGGLE_GIFT',
  is_gift
}); // todo: this could just be part of update, just trying to limit the scope for now

const Order = BackboneRXModel.extend({
  findCartItems: Ent.query(Ent.find('cart_item'), Ent.join('variant'), Ent.join('product_grouping')),
  findSuppliers: Ent.query(Ent.find('supplier'), Ent.join('delivery_methods')),
  defaults: {
    is_gift: false,
    replenishment: false,
    replenishment_interval: 1
  },
  blacklist: ['payment_profile', 'shipping_address'],
  toJSON: function(options) {
      return _.omit(this.attributes, this.blacklist);
  },
  isActive: false,
  isSyncing: false,
  isFinalizing: false,
  reset: false,
  trackOrder: false,
  rootUrl: `${window.api_server_url}/api/v2/order/`,
  url: function(){
    return (this.get('number') ? this.rootUrl + this.get('number') + '/' : this.rootUrl);
  },
  initialize: function(){
    this.set('order_items', []);
    this.trackOrder = _.once(this.track);

    this.subscribeToDispatcher();
    this.listenTo(Store.Cart,  'cart:change', this.updateItems);
    this.listenTo(Store.DeliveryAddress, 'delivery_address:found_suppliers', this.setAddress);
    this.listenTo(Store.PickupDetail, 'pickup_detail:saved', this.setPickupDetail);

    this.store$
      .subscribe(({action, state}) => {
        switch (action.type){
          case('ORDER:RESET_SHIPMENT_SCHEDULING'):
            return this.resetShipmentScheduling(action);
          case('ORDER:SET_SHIPMENT_SCHEDULING'):
            return this.setShipmentScheduling(action);
          case('SUPPLIER:SELECT_DELIVERY_METHOD'):
            return this.setDeliveryMethod(action);
        }
      });

    model_stream.next(this);
  },

  subscribeToDispatcher: function(){
    actionStream('ORDER_TOGGLE_GIFT')
      .subscribe(action => {
        this.set('is_gift', action.is_gift);
        model_stream.next(this);
      });
  },

  updateItems: function(){
    var model = this;

    // TODO: can this be separated out?
    if(window.bttnio) model.set('button_referrer_token', window.bttnio('getReferrerToken'));

    model.resetItems();
    model.resetTip();

    const redux_state = this.storeGetState();
    const cart_items = this.findCartItems(redux_state, cart_item_selectors.getAllCartItemIds(redux_state));
    cart_items.forEach(item => {
      const {id, supplier_id, quantity} = item;
      const delivery_method_id = supplier_selectors.supplierSelectedDeliveryMethod(redux_state, supplier_id);
      Store.Order.addItem({id, supplier_id, quantity, delivery_method_id});
    });

    model.resetOrder(); // reset order if items change
    model_stream.next(model);
  },

  getShipments(){ // internal helper
    const redux_state = this.storeGetState();
    const cart_items = this.findCartItems(redux_state, cart_item_selectors.getAllCartItemIds(redux_state));
    const suppliers = this.findSuppliers(redux_state, supplier_selectors.currentSupplierIds(redux_state));
    const selected_delivery_methods = supplier_selectors.selectedDeliveryMethods(redux_state);
    return getOrderShipments(this.toPure(), cart_items, suppliers, selected_delivery_methods);
  },

  validate: function(){
    var default_error_name = 'InvalidOrder';

    // TODO: these seem to cause issues with the place order button
    if (this.isFinalizing){
      var order_item_errors = this.validateOrderItems();
      if (!_.isEmpty(order_item_errors)){
        return order_item_errors[0];
      }
    }
  },
  validateOrderItems: function(){
    const shipment_errors = this.getShipments()
      .map(validateShipment)
      .filter(error => !!error);

    return shipment_errors;
  },
  readyToSync: function(){
    var err = null;
    if(this.get('payment_profile_id') === undefined){
      err = 'No Billing Info ID defined';
    }
    if(this.addressMissing()){
      err = 'No Shipping Address ID defined';
    }
    if(this.pickupMissing()){
      err = 'No Pickup Detail ID defined';
    }
    if(this.get('order_items').length < 1){
      err = 'No Items in Order';
    }
    return _.isNull(err);
  },
  setDefaults: function(){
    var payment_profile = User.defaultPaymentProfile();
    if(payment_profile){
      this.set( { 'payment_profile_id': payment_profile.id }, { silent: true });
    }
    this.setAddress();
    this.setPickupDetail();

    const stored_promo = getPromoCodeFromStorage();
    if (stored_promo){
      this.setPromoCode(stored_promo);
    }
  },
  setAddress: function(){
    if(Store.DeliveryAddress.get('id') === null){
      // Need to prompt user to review address and save it on the user
    } else {
      var address_id = Store.DeliveryAddress.get('id'),
        address = User.findShippingAddress(address_id) || Store.DeliveryAddress.attributes;

      if(address){
        this.set({
          'shipping_address': address,
          'shipping_address_id': address.id
        }, { silent: false });
      }
    }
  },
  setPickupDetail: function(){
    if (!Store.PickupDetail.get('id')){
      // Need to prompt user to enter pickup detail and save it
    } else {
      const pickup_detail = Store.PickupDetail.attributes;

      if (pickup_detail){
        this.set({
          pickup_detail: pickup_detail,
          pickup_detail_id: pickup_detail.id
        }, { silent: false });
      }
    }
  },
  completed: function(){
    return this.get('state') === 'paid';
  },
  addItem: function(item){
    this.get('order_items').push(item);
  },
  resetItems: function(){
    this.set({ order_items: [] });
  },
  setTip: function(tip){
    this.set('tip', tip);
  },
  resetTip: function(){
    this.set('tip', undefined); // Setting this to undefined forces the server to update the value?
  },
  setPromoCode: function(code){
    this.set('promo_code', code);
  },
  removePromoCode: function(code){
    removePromoCodeFromStorage();
    this.set('promo_code', '', { silent: true });
  },
  checkValidError: function(errors){
    var errors = typeof errors !== 'undefined' ? errors : []; //make empty array if undefined

    var true_error = _.find(errors, function(err){ //first with valid error code
      return !_.includes([400, 401, 404, 500, 501, 900], err.code); //500 errors are given a code of 900
    });
    true_error = true_error || {}; //empty object will give us default error modal

    return true_error;
  },
  createOrder: function(){
    return this.sync();
  },
  updateOrder: function(){
    return this.sync();
  },
  resetOrder: function(){
    this.reset = true; // next time it's updated, it'll renew
  },
  finalize: function(){
    this.isFinalizing = true;
    var model = this;
    var prom = model.action('actions/finalize/', 'create');
    prom.done(function(response){
      model.trackOrder();
      model.trigger('order:charge:success');
      model.removePromoCode(); // nuke it, will also clear it from session storage
    });
    prom.always(function(response){
      model.isFinalizing = false;
    });
    return prom;
  },
  sync: function(method, options, charging){ //TODO: pull out charge flag when payment errors cleaned up
    var model = this;
    method    = model.syncMethod(method);
    options   = options || {};
    options.headers = { 'X-Minibar-User-Token' : User.getAccessToken() };
    options.url     = options.url || (method === 'create' ? this.rootUrl : this.url());

    //this.updateItems();
    if(model.syncable() && model.isValid()){
      model.isSyncing = true;
      model.trigger('order:syncing');
      var prom = Backbone.sync(method, model, options);
      prom.always(function(){
        model.isSyncing = false;
        model.reset     = false;
        model_stream.next(model);
      });
      prom.done(function(response, textStatus, jqXHR){
        model.trigger('order:promo:valid', { promo_code: response.promo_code } );
        model.set(response, { silent: true }); //don't trigger an update
        model.setTotals(response.amounts);
        model.trigger('order:validated');
      });
      prom.fail(function(response){
        var response_json = response.responseJSON;
        if (response_json && response_json.error){
          if (response_json.error.number){
            model.set('number', response_json.error.number);
          }

          if (response_json.error.name === 'InvalidPromoCode'){
            model.removePromoCode();
            model.sync(); //updating, order without promo
          }

          if (!charging){
            model.setTotals(response_json.error.amounts);
            model.trigger('order:invalid', response_json.error);
          } else { //still has issues if it's failing a validation
            model.trigger('order:charge:error', { description: response_json.error });
            Raven.setExtraContext({
                response: response_json
            });
            Raven.captureMessage('Order Finalize Error: ' + response_json.error.message);
          }
        }
      });
      return prom;
    } else {
      // if the only issue was that it was invalid
      if(model.syncable()) {
        Raven.captureMessage('Order Validation Error: ' + Store.Order.validationError);
        model.trigger('order:invalid', Store.Order.validationError);
      }
      return $.Deferred().reject(); //return dummy error promise
    }
  },

  action:function(endpoint, method, options) {
    var options = options || {};
    options.url = this.url() + endpoint;
    return this.sync(method, options, true);
  },

  syncMethod: function(method){
    if (method){
      method = method;
    } else if (this.reset || !this.get('number')){
      method = 'create';
    } else {
      method = 'update';
    }
    return method;
  },

  setTotals: function(amounts){
    if(!_.isUndefined(amounts) && !_.isNull(amounts)){
      this.set({
        coupon_amount:    this.formatAmount('coupon_amount', amounts.discounts.coupons),
        deal_amount:      this.formatAmount('deal_amount', amounts.discounts.deals),
        shipping_charges: this.formatAmount('shipping_charges', amounts.shipping),
        sub_total:        this.formatAmount('sub_total', amounts.subtotal),
        taxed_amount:     this.formatAmount('taxed_amount', amounts.tax),
        tip:              this.formatAmount('tip', amounts.tip),
        total_amount:     this.formatAmount('total_amount', amounts.total)
      }, {silent: true});
    }
  },

  formatAmount: function(key, new_val){
    return !_.isUndefined(new_val) && !_.isNull(new_val) ? parseFloat(new_val).toFixed(2) : this.get(key)
  },

  updateOrderItems: function(attributes, supplier_id){
    var model = this;
    _.each(attributes, function(value, attr_name){
      _.each(model.get('order_items'), function(item){
        if (item.supplier_id == supplier_id)
          item[attr_name] = value;
      });
    })

    model_stream.next(this);
  },

  clearGiftOptions: function(){
    this.unset('gift_options')
    this.unset('message')
    this.unset('gift_recipient')
    this.unset('gift_recipient_phone')
  },

  syncable: function(){
    return (this.readyToSync() && this.isActive && !this.isSyncing && this.get('state') !== 'Order Placed');
  },

  matchesDeliveryAddress: function(){
    return this.get('shipping_address_id') === Store.DeliveryAddress.get('id');
  },

  activate: function(){
    this.isActive = true;
  },
  deactivate: function(){
    this.isActive = false;
  },
  getItemQuantity: function(){
    var total = 0;
    _.each(this.get('order_items'), function(item){
      total = total + item.quantity;
    });
    return total;
  },
  track: function(){
    var model = this,
        dataLayer = window.dataLayer || [];

    // Google Tag Manager Variables
    dataLayer.push({ quantity: model.getItemQuantity() });
    dataLayer.push({ revenue: model.get('total_amount')});
    dataLayer.push({ sub_total: model.get('sub_total')});
    dataLayer.push({ number: model.get('number')});
    dataLayer.push({ coupon_code: model.get('promo_code') });
    dataLayer.push({ test_group: User.get('test_group') });
    dataLayer.push({ email: User.get('email') });

    // Track the number of orders
    if(typeof User.get('order_count') === 'number') dataLayer.push({'order_count' : User.get('order_count')});

    const redux_state = this.storeGetState();
    const cart_items = this.findCartItems(redux_state, cart_item_selectors.getAllCartItemIds(redux_state));

    cart_items.forEach(item => {
      dataLayer.push({
        ecommerce: {
          purchased_product: {
            id: item.id,
            brand: item.product_grouping.brand,
            category: item.product_grouping.category,
            price: item.variant.price,
            name: item.product_grouping.name + ' ' + item.variant.volume,
            quantity: item.quantity
          }
        }
      });
    });

    dataLayer.push({ event: 'purchase' });

    // Begin Facebook Product-Level Tracking
    if(model.get('tracking') !== undefined) {
      _.each(_.keys(model.get('tracking')), function(key){
        dataLayer.push({ 'fb_tracking_data' : model.get('tracking')[key] });
        dataLayer.push({ 'event' : key });
      });
    }
    // End Facebook Product-Level Tracking

    gtag('event', 'purchase', {
      transaction_id: model.get('number'),
      affiliation: 'Minibar - Web',
      value: model.get('total_amount'),
      currency: 'USD',
      shipping: model.get('shipping_charges'),
      tax: model.get('taxed_amount'),
      items: cart_items.map(item => ({
        id: item.id,
        brand: item.product_grouping.brand,
        category: item.product_grouping.category,
        price: item.variant.price,
        name: item.product_grouping.name + ' ' + item.variant.volume,
        quantity: item.quantity,
        coupon: model.get('promo_code')
      }))
    });
  },

  hasAddressShipments(){
    return shipment_helpers.hasAddressShipments(this.getShipments());
  },
  hasPickupShipments(){
    return shipment_helpers.hasPickupShipments(this.getShipments());
  },

  addressMissing(){
    // check if the prereq is actually relevant to this order
    if (!this.hasAddressShipments()) return false;

    // if we don't have the shipping address, or the one in the store is otherwise invalid, consider it missing
    const invalied_address = Store.DeliveryAddress.isLocal() || !Store.Order.matchesDeliveryAddress() || !Store.DeliveryAddress.hasPhone();
    return !this.get('shipping_address_id') || invalied_address;
  },
  pickupMissing(){
    // check if the prereq is actually relevant to this order
    if (!this.hasPickupShipments()) return false;

    return !this.get('pickup_detail_id');
  },

  // action handlers
  resetShipmentScheduling(action: Object){
    const {is_scheduled, supplier_id} = action.payload;

    // update the order items to reflect the mid state, nuke scheduled_for
    this.updateOrderItems({
      scheduled: is_scheduled,
      scheduled_for: null
    }, supplier_id);
  },
  setShipmentScheduling(action: Object){
    const {scheduled_for, supplier_id} = action.payload;

    this.updateOrderItems({
      scheduled: true, // just in case!
      scheduled_for
    }, supplier_id);
    this.trigger('order:scheduled');
  },
  setDeliveryMethod(action: Object){
    const {delivery_method_id, supplier_id} = action.payload;

    this.updateOrderItems({
      delivery_method_id: delivery_method_id,
      scheduled: false,  // reset these in case they've been set
      scheduled_for: null
    }, supplier_id);

    this.updateOrder(); // just to be safe
  }
});

export default Order;
export const orderStream = toObjectStream(model_stream);

//TODO: remove! use real dependencies!
window.Order = Order;
