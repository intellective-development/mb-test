import _ from 'lodash';
import { BackboneRXModel, requestActionToPromise } from 'shared/utils/backbone_rx';
import apiAuthenticate from 'shared/web_authentication';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { address_actions } from 'store/business/address';
import { payment_profile_actions, payment_profile_selectors } from 'store/business/payment_profile';
import { user_actions, user_selectors } from 'store/business/user';

function loggedIn(user){
  return user.user_token !== undefined;
}

// these are the properties that should be made directly available on the model via redux
const PROPERTY_WHITELIST = [
  'id',
  'email',
  'hashed_email',
  'first_name',
  'last_name',
  'referral_code',
  'order_count',
  'user_token',
  'test_group'
];

const user = BackboneRXModel.extend({
  pickupDetailUrl: `${window.api_server_url}/api/v2/user/pickup/`,

  findUser: Ent.query(Ent.find('user'), Ent.join('shipping_addresses', 'address')),
  findPaymentProfiles: Ent.find('payment_profile'),
  newUser: true,
  initialize: function(options){
    this.listenTo(this, 'user:created', this.setUserCookies);
    this.listenTo(this, 'login:success', this.setUserCookies);
    this.listenTo(this, 'login:success', this.setSiftScienceUser);

    Raven.setUser({
      email:    this.get('email'),
      username: this.get('referral_code')
    });

    apiAuthenticate(this.getAccessToken());

    this.freezeModel((buildGetAttributeError) => (property_name) => {
      if (property_name === 'shipping_addresses'){
        return this.getReduxShippingAddresses();
      } else if (property_name === 'payment_profiles'){
        return this.getReduxPaymentProfiles();
      } else if (PROPERTY_WHITELIST.includes(property_name)){
        const redux_data = this.getReduxUser();
        return redux_data && redux_data[property_name];
      } else {
        throw buildGetAttributeError(property_name);
      }
    });
  },

  // the newUser value is used exclusively for routing in checkout.
  // should pull into view state when possible
  setNewUser(next_val){
    this.newUser = next_val;
    this.trigger('new_user_changed');
  },

  setSiftScienceUser: function(){
    var _sift = window._sift || [];
    _sift.push(['_setUserId', User.get('referral_code')]);
  },

  signUp: function(user_data){
    if (this.getAccessToken()) return null;

    const request_action = user_actions.createAccount(user_data);
    this.storeDispatch(request_action);
    requestActionToPromise(this.store$, request_action)
      .then(
        (response_action) => {
          this.setNewUser(false);
          this.trackUserInDatalayer();
          apiAuthenticate(this.getAccessToken());
          this.trigger('user:created');
        },
        (error_action) => {
          const error_message = _.get(error_action, 'payload.error.message');
          this.trigger('user:error', error_message);
        }
      );
  },
  attemptLogin: function(email, password){
    const request_action = user_actions.logInUser(email, password);
    this.storeDispatch(request_action);

    requestActionToPromise(this.store$, request_action)
      .then(
        (response_action) => {
          this.trackUserInDatalayer();
          apiAuthenticate(this.getAccessToken()); // support legacy requests
          this.trigger('login:success');
        },
        (error_action) => {
          this.trigger('login:error');
        }
      );
  },
  trackUserInDatalayer(){
    const dataLayer = window.dataLayer || [];
    dataLayer.push({'Referral Code': this.get('referral_code')});
    dataLayer.push({'hashed_email': this.get('hashed_email')});
  },
  addPaymentProfile: function(payment_details){
    const request_action = payment_profile_actions.createProfile(payment_details);
    this.storeDispatch(request_action);

    requestActionToPromise(this.store$, request_action)
      .then(
        (response_action) => {
          this.trigger('user:payment_profile:added', { payment_profile_id: response_action.payload.result });
        },
        (error_action) => {
          const error_message = _.get(error_action, 'payload.error.message');
          Raven.captureMessage('Credit Card Validation Error: ' + error_message);
          this.trigger('user:payment_profile:error', 'We were unable to verify your credit card information. Please verify your card details and billing address, or try another card.');
        }
      );
  },
  defaultPaymentProfile: function(){
    const payment_profiles = this.get('payment_profiles');
    var defaultPaymentProfile = _.find(payment_profiles, function(payment_profile){
      return payment_profile.default === true;
    });
    if(defaultPaymentProfile === undefined && this.loggedIn() && payment_profiles.length > 0){
      defaultPaymentProfile = payment_profiles[0];
    }
    return defaultPaymentProfile;
  },
  findPaymentProfile: function(payment_profile_id){
    return this.get('payment_profiles').find(payment_profile => payment_profile.id === payment_profile_id);
  },
  addShippingAddress: function(address){
    const request_action = address_actions.saveDeliveryAddress(address);
    this.storeDispatch(request_action);
    requestActionToPromise(this.store$, request_action)
      .then(
        null,
        (error_action) => {
          const error_message = _.get(error_action, 'payload.error.message'); // TODO: do we still need this logging client side?
          Raven.captureMessage('Address Validation Error: ' + error_message);
          this.trigger('user:shipping_address:error', error_message);
        }
      );
  },
  addPickupDetail: function(pickup_detail){
    var model = this;
    if (pickup_detail.isValid()){
      $.ajax({
        url: model.pickupDetailUrl,
        method: 'POST',
        data: pickup_detail.toJSON(),
        headers: { 'X-Minibar-User-Token': User.getAccessToken() },
        dataType: 'json',
        success: function(data, textStatus, jqXHR){
          model.trigger('user:pickup_detail_added', data);
        },
        error: function(jqXHR, textStatus, errorThrown){
          Raven.captureMessage('Pickup Detail Error: ' + errorThrown);
          model.trigger('user:pickup_detail:error', jqXHR.responseJSON.error);
        }
      });
    } else {
      Raven.captureMessage('Pickup Detail Validation Error: ' + pickup_detail.validationError);
    }
  },
  defaultShippingAddress: function(){ // unused?
    return _.find(this.get('shipping_addresses'), function(address){
      return address.default === true;
    });
  },
  findShippingAddress: function(id){
    return _.find(this.get('shipping_addresses'), function(address){
      return address.id == id;
    });
  },
  matchShippingAddress: function(address1, zip_code){ // unused?
    return _.find(this.get('shipping_addresses'), function(address){
      return address.address1 === address1 && address.zip_code === zip_code;
    });
  },
  getAccessToken: function(){
    if (this.loggedIn()){
      return this.get('user_token');
    }
  },
  loggedIn: function(){
    return loggedIn(this.getReduxUser() || {});
  },
  hasAddresses: function(){ // unused?
    return this.get('shipping_addresses').length > 0;
  },
  fullName: function(){
    return this.get('first_name') + ' ' + this.get('last_name');
  },
  referralCode: function(){ // 1 Use, appears to be primarily for formatting during checkout
    var code = this.get('referral_code');
    if(code !== undefined) code = code.toUpperCase();
    return code;
  },

  getReduxUser: function(){
    const state = this.storeGetState();
    return this.findUser(state, user_selectors.currentUserId(state));
  },

  getReduxShippingAddresses: function(){
    const current_user = this.getReduxUser();
    return current_user && current_user.shipping_addresses;
  },

  getReduxPaymentProfiles: function(){
    const state = this.storeGetState();
    return this.findPaymentProfiles(state, payment_profile_selectors.getUserPaymentProfileIds(state));
  }
});

export default user;

//TODO: remove! use real dependencies!
window.Store.user = user;
