import _ from 'lodash';
import Rx from 'rxjs';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { supplier_selectors } from '@minibar/store-business/src/supplier';
import { BackboneRXCollection, toObjectStream } from 'shared/utils/backbone_rx';
import { utf8ToB64 } from 'shared/utils/convert_utf8_b64';
import { testLS } from 'shared/utils/check_storage_supported';
import Supplier from 'legacy_store/models/Supplier';
import { ui_actions } from 'store/business/ui';

const REDUX_ACTIONS = [
  // actions that signify a change from one set of current suppliers to another
  'SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__SUCCESS',
  'SUPPLIER:SWAP_CURRENT_SUPPLIER',

  // actions that signify updates to the existing set of current suppliers, or initializing them
  'SUPPLIER:FETCH_SUPPLIERS_BY_IDS__SUCCESS',
  'SUPPLIER:REFRESH_SUPPLIERS__SUCCESS',
  'SUPPLIER:SELECT_DELIVERY_METHOD',
  'persist/REHYDRATE'
];

const REDUX_ERROR_ACTIONS = [
  'SUPPLIER:REFRESH_SUPPLIERS__ERROR'
];

const collection_stream = new Rx.ReplaySubject(1);
const findSuppliers = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));

const Suppliers = BackboneRXCollection.extend({
  model: Supplier,
  url: function(){
    return `${window.api_server_url}/api/v2/supplier/${this.supplier_ids.join(',')}`;
  },
  initialize: function(){
    this.listenTo(this, 'reset', () => {
      collection_stream.next(this); //reset is always called while intializing
    });

    this.store$
    .filter(({action}) => REDUX_ERROR_ACTIONS.includes(action.type))
    .subscribe(({action}) => {
      if(action && action.payload && action.payload.response && action.payload.response.status === 404) {
        const request_action = ui_actions.showDeliveryInfoModal();
        this.storeDispatch(request_action);
      }
    });

    this.store$
      .filter(({action}) => REDUX_ACTIONS.includes(action.type))
      .subscribe((...args) => {        
        this.handleReduxChange(...args);
      });
  },
  handleReduxChange: function({action, state}){ // whenever the current delivery address is affected in redux, we update this collection to reflect those changes
    const current_suppliers = findSuppliers(state, supplier_selectors.currentSupplierIds(state))
    .map(supplier => ({
      ...supplier,
      selected_delivery_method_id: supplier_selectors.supplierSelectedDeliveryMethod(state, supplier.id)
    }));

    // there is no valid situation where we want to sync up an empty supplier group, but they can be attached to PERSIST actions
    if (_.isEmpty(current_suppliers)) return null;

    if (action.type === 'persist/REHYDRATE'){      
      this.reset(current_suppliers);
      this.trigger('suppliers:ready');
    } else if (action.type === 'SUPPLIER:SWAP_CURRENT_SUPPLIER'){
      this.reset(current_suppliers);
      this.trigger('suppliers:changed');
    } else if (action.type === 'SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__SUCCESS'){
      this.reset(current_suppliers);
      this.trigger('suppliers:changed');
    } else if (action.type === 'SUPPLIER:SELECT_DELIVERY_METHOD'){
      this.reset(current_suppliers);
      this.trigger('suppliers:delivery_method_changed');
    } else {
      // the first time, we trigger the ready action only if going from an empty supplier collection to a full one
      // this is to mirror the legacy behavior where we triggered suppliers:changed/reset actions on the first supplier load,
      // but not on subsequent loads triggered by the heartbeat.
      if (this.isEmpty()){
        this.reset(current_suppliers); // get current suppliers
        this.trigger('suppliers:ready');
      } else {
        this.reset(current_suppliers); // get current suppliers
      }
    }
  },
  reset: function(models, options){
    Backbone.Collection.prototype.reset.call(this, models, options);
  },
  supplierIDs: function(){
    return Store.Suppliers.pluck('id').join(',');
  },
});

export default Suppliers;
export const supplierStream = toObjectStream(collection_stream);

export function hasChanged(stream, {skip_first = false} = {}){
  const changed_stream = stream.distinctUntilChanged((suppliers, next_suppliers) => {    
    // only care about ids, sort but first, make sure they're in the same order for _.isEqual
    const supplier_ids = suppliers.map(supplier => supplier.id).sort();
    const next_supplier_ids = next_suppliers.map(supplier => supplier.id).sort();
    return _.isEqual(supplier_ids, next_supplier_ids);
  });

  return skip_first ? changed_stream.skip(1) : changed_stream;
}

// Stream that will emit a boolean once, when we first have suppliers
export const supplierLoadedStream = supplierStream
  .map(suppliers => _.some(suppliers))
  .filter(has_suppliers => has_suppliers)
  .take(1);

//TODO: remove! use real dependencies!
window.Suppliers = Suppliers;
