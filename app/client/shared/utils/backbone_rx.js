import _ from 'lodash';
import Rx from 'rxjs';
import store from '../../store/data_store';
import { store$ } from '../../store/business/legacy_link/epics';
import { request_status_constants } from '../../store/business/request_status';
import { analytics_actions, analytics_helpers} from '../../store/business/analytics';
import { cart_item_selectors } from '../../store/business/cart_item';

// TODO: this is a helper for backbone transition. Rip out when possible

export const BackboneRXModel = Backbone.Model.extend({
  store$,
  storeDispatch: store.dispatch,
  storeGetState: store.getState,

  freezeModel(makeGet = null){
    // prevent direct access to all model properties
    const buildPropertyError = (property) => new Error(`Model Error: Can not directly access ${property}.`);
    // const buildPropertyWarning = (property) => console.warn(`Model Warning: Backbone internally accessed ${property}.`);
    const addErrors = property => Object.defineProperty(this, property, {
      get(){ throw buildPropertyError(property); },
      set(){ throw buildPropertyError(property); }
    });
    const addWarnings = property => Object.defineProperty(this, property, {
      get(){
        // buildPropertyWarning(property); // <-- uncomment while working on backbone models
        return this[`_${property}`];
      },
      set(value){
        // buildPropertyWarning(property); // <-- uncomment while working on backbone models
        this[`_${property}`] = value;
      }
    });

    Object
      .getOwnPropertyNames(this)
      .map(property => ((!_.startsWith(property, '_')) ? addErrors(property) : addWarnings(property)));

    // prevent setting attributes through the set method
    const buildSetAttributeError = () => new Error('Model Error: Can not "set" directly.');
    this.set = () => { throw buildSetAttributeError(); };

    // prevent getting attributes through the get method.
    // If makeGet is provided, we call that. Otherwise, get is assigned to throw errors
    const buildGetAttributeError = (property_name) => (
      new Error(`Model Error: Can not access "${property_name}" directly on the model instance.`)
    );
    if (makeGet){
      this.get = makeGet(buildGetAttributeError);
    } else {
      this.get = (property_name) => { throw buildGetAttributeError(property_name); };
    }
  },

  toPure(){
    return this.attributes;
  }
});

// TODO: this is a helper for backbone transition. Rip out when possible
export const BackboneRXCollection = Backbone.Collection.extend({
  store$,
  storeDispatch: store.dispatch,
  storeGetState: store.getState,
  toPure(){
    return this.map((model) => model.toPure());
  }
});

export const BackboneRXView = Backbone.View.extend({
  store$,
  storeDispatch: store.dispatch,
  storeGetState: store.getState,
  storeSubscribe: store.subscribe,
  trackScreen(name){
    store.dispatch(analytics_actions.track({
      action: `${name}`
    }));
    cart_item_selectors.getAllCartItems(store.getState()).forEach(({ product_grouping, variant, quantity }) =>
      store.dispatch(analytics_actions.track({
        action: `${name}`,
        content_type: 'product',
        items: [analytics_helpers.getCartItemData(product_grouping, variant, quantity)]
      })));
  }
});

export const toObjectStream = function(model_stream){
  return model_stream
    .filter(coll => _.isObject(coll))
    .map((coll) => _.clone(coll.toPure()));
};

export const aggregateMetadataStream = function(metadataFragmentStream){
  return metadataFragmentStream
    // allows us to push a single metadata value at a time to the in stream without other values
    .scan((metadata, metadata_fragment) => _.assignIn(metadata, metadata_fragment))

    //makes the below withLatestFrom work properly
    .startWith({});
};

// this will return an observable (for use in flatMap) whose values are either
// response { remote_val_1: foo ... }
// response { error: foo }
export const safeRequestObservable = function(prom){
  const request_obs = Rx.Observable.from(prom);
  const safe_request_obs = request_obs.catch((error) => Rx.Observable.of({error: error}));
  return safe_request_obs;
};

export const requestActionToPromise = (store_action$, initial_action) => {
  const updated_address_prom = store_action$
    .filter(({action}) => isRequestCompleted(action, initial_action.meta.request_data.request_id))
    .take(1)
    .mergeMap(({action}) => {
      if (action.meta.request_data.status === request_status_constants.ERROR_STATUS){
        return Promise.reject(action);
      } else {
        return Promise.resolve(action);
      }
    })
    .toPromise();

  return updated_address_prom;
};

const isRequestCompleted = (action, request_id) => {
  const request_data = _.get(action, 'meta.request_data');
  if (!request_data) return false;

  const completed_status = request_data.status === request_status_constants.SUCCESS_STATUS || request_data.status === request_status_constants.ERROR_STATUS;
  const correct_request = request_data.request_id === request_id;
  return completed_status && correct_request;
};

