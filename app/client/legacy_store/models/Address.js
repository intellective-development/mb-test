import _ from 'lodash';
import Rx from 'rxjs';
import { normalize } from 'normalizr';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { address_schema } from '@minibar/store-business/src/networking/schemas';
import { address_selectors } from 'store/business/address';
import { request_status_constants } from 'store/business/request_status';
import { BackboneRXModel, toObjectStream } from 'shared/utils/backbone_rx';

const modelStream = new Rx.ReplaySubject(1);
const REDUX_UPDATE_ACTIONS = [
  'persist/REHYDRATE',
  'ADDRESS:CREATE_DELIVERY_ADDRESS', // not certain we need this one
  'ADDRESS:SAVE_DELIVERY_ADDRESS__SUCCESS',
  'SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__SUCCESS' // changes the current_id
];

const REDUX_ERROR_ACTIONS = [
  'SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__ERROR'
];

const findAddress = Ent.find('address');

// there is only 1 instance of address (what does billing address use?).
// Therefore, we can simply have it connect to redux by doing Ent.find('address')(state, current_address_id)

var Address = BackboneRXModel.extend({
  // url: `${window.api_server_url}/api/v2/suppliers`,
  initialize: function(attributes = {}){
    // this is not ideal, but many parts of the store rely on the address being synchronously available.
    // which, since we're bootstrapping it in with initStore, it should be
    this.consumeReduxState({action: {}, state: this.storeGetState()});

    this.store$
      .filter(({action}) => REDUX_UPDATE_ACTIONS.includes(action.type))
      .subscribe((...args) => {
        this.consumeReduxState(...args);
      });
  },
  consumeReduxState: function({action, state}){ // whenever the current delivery address is affected in redux, we update this model to reflect those changes
    const current_address = findAddress(state, address_selectors.currentDeliveryAddressId(state));

    // If the address is null in state (mostly, outside the store) then do nothing
    if (!current_address) return null;

    this.setFromRedux(current_address);
    if (action.type === 'ADDRESS:SAVE_DELIVERY_ADDRESS__SUCCESS') this.handleAddressSaved();
  },
  handleAddressSaved(){
    if (this.get('id') === Store.DeliveryAddress.get('id')){ // if this is the delivery address
      Store.Order.setAddress();
      this.trigger('delivery_address:associated');
    }
  },
  setFromRedux: function(address){
    this.clear({silent: true}).set(address, {silent: true});

    this.trigger('delivery_address:found_suppliers');
    modelStream.next(this);
  },

  validate: function(attributes){}, // ?
  isLocal: function(){ // 1 external use (DANGER! id attribute is overloaded)
    return this.get('id') == null;
  },
  isPresent: function(){ // many uses
    return this.get('address1') != null;
  },
  hasPhone: function(){ // 1 use
    return this.get('phone') != null;
  },
  formatAddress: function(address){
    var address = address || this.attributes;
    var params = {};
    if(address.id){
      params = {
        aid: address.id
      }
    } else if (address.latitude && address.longitude){
      params = {
        coords: {
          lat: address.latitude,
          lng: address.longitude
        }
      }
    } else {
      params = {
        address: {
          address1: address.address1,
          address2: address.address2 || '',
          city: address.city,
          state: address.state,
          zip_code: address.zip_code
        }
      }
    }
    return params;
  },
  formattedPhoneNumber: function(){ // 1 external
    // This is a much larger kettle of fish, but for now we'll just assume we have a
    // US phone number without symbols, dashes and such; and attempt to format it.
    var phone = this.get('phone');
    if (phone && phone.length == 10){
      return phone.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
    } else {
      return phone;
    }
  }
});

function addressComponents(address){
  return _.compact([address.address1, address.address2, address.city, address.state, address.zip_code]);
}
function shortAddressComponents(address){
  return _.compact([address.address1, address.address2]);
}

export function displayAddress(address, {allow_shorten} = {}){
  const full_address = addressComponents(address).join(', ');
  return allow_shorten && full_address.length > 60 ? shortAddressComponents(address).join(', ') : full_address;
}

export default Address;
export const addressStream = toObjectStream(modelStream);

//TODO: remove! use real dependencies!
window.Address = Address;
