// @flow
import Rx from 'rxjs';
import _ from 'lodash';
import type { Observable, StateObservable } from 'rxjs';
import type { ActionWeaklyTyped, GlobalState } from '@minibar/store-business/src/constants';
import * as Ent from '@minibar/store-business/src/utils/ent';
import type { CartItem } from 'store/business/cart_item';
import { actionStream } from 'shared/dispatcher';
import { locationStream } from 'legacy_store/router/StoreRouter';
import * as helpers from './helpers';
import * as analytics_actions from './actions';
import type { TrackActionParams } from './actions';
import { trackCheckoutStep, transformPageTrackingLocation, trackPageView } from './legacy_tracking_code';

const gtag = window.gtag;
const findCartItem = Ent.query(Ent.find('cart_item'), Ent.join('product_grouping'), Ent.join('variant'));
const findVariant = Ent.find('variant');
const findProductGrouping = Ent.find('product_grouping');
const findUser = Ent.find('user');

// OLD PORTED tracking.js CODE
const trackCheckoutSteps = (action$: Observable<ActionWeaklyTyped>) => {
  actionStream('track:checkout_step')
    .withLatestFrom(locationStream, (action, location) => (
      {action, location}
    ))
    .filter(({location}) => location.page_type === 'checkout')
    .map(({action}) => action)

    // we only subscribe to tracking actions fired when checkout visible
    .subscribe(trackCheckoutStep);

  return action$.filter(() => false);
};

const trackPageViews = (action$: Observable<ActionWeaklyTyped>) => {
  locationStream
    .map(transformPageTrackingLocation)
    .subscribe(trackPageView);

  return action$.filter(() => false);
};

export const trackVirtualPageViews = (action$: Observable<ActionWeaklyTyped>) => (
  action$
    .filter(action => action.type === '@@router/LOCATION_CHANGE')
    .map((action) => {
      const { location } = action.payload;

      trackPageView(location.pathname);

      return action;
    })
    .filter(() => false)
);

export const trackPurchase = (action$: Observable<ActionWeaklyTyped>, state$: StateObservable<GlobalState>) => (
  action$
    .filter(action => action.type === 'ANALYTICS:TRACK_PURCHASE')
    .map((action) => {
      const order = action.payload.order;
      const state = state$.getState();
      const { order_items, tracking, amounts } = order;

      const num_items = order_items.reduce((acc, item) => (acc + item.quantity), 0);
      const user = findUser(state, state.user.current_user_id) || window.User.get('new_user');

      const dataLayer = window.dataLayer || [];

      // Google Tag Manager Variables
      dataLayer.push({ coupon_code: order.promo_code });
      dataLayer.push({ email: user && user.email });
      dataLayer.push({ hashed_email: user && user.hashed_email });
      dataLayer.push({ number: order.number});
      dataLayer.push({ quantity: num_items });
      dataLayer.push({ revenue: amounts.total});
      dataLayer.push({ sub_total: amounts.subtotal});
      dataLayer.push({ test_group: user && user.test_group });

      // Track the number of orders
      if (user && typeof user.order_count === 'number') dataLayer.push({ order_count: user.order_count });

      if (tracking !== undefined){
        Object.keys(tracking).forEach(key => {
          dataLayer.push({ fb_tracking_data: tracking[key] });
          dataLayer.push({ event: key });
        });
      }

      order_items.map((item) => {
        return dataLayer.push({
          ecommerce: {
            purchased_product: getItemDetails(item, state)
          }
        });
      });

      gtag('event', 'purchase', {
        affiliation: 'Minibar - Web',
        currency: 'USD',
        items: order_items.map(item => (getItemDetails(item, state))),
        shipping: _.get(order, 'amounts.shipping'),
        tax: _.get(order, 'amounts.tax'),
        transaction_id: _.get(order, 'number'),
        value: _.get(order, 'amounts.total')
      });

      return action;
    })
    .filter(() => false)
);

const getItemDetails = (item, state) => {
  const variant = findVariant(state, item.id);
  const product_grouping = findProductGrouping(state, item.product_id);

  return {
    id: _.get(item, 'id'),
    brand: _.get(product_grouping, 'brand'),
    category: _.get(product_grouping, 'category'),
    price: _.get(variant, 'price'),
    name: [
      _.get(product_grouping, 'name'),
      _.get(variant, 'volume')
    ].join(' '),
    quantity: _.get(item, 'quantity'),
    product_id: _.get(variant, 'product_id'),
    supplier_id: _.get(item, 'supplier_id'),
    coupon: _.get(item, 'promo_code')
  };
};

// Google Analytics
/*
For reference:
Old ga tracking used parameter order for everything.
ga('send', 'event', [eventCategory], [eventAction], [eventLabel], [eventValue], [fieldsObject]);
*/
export const googleAnalyticsRootEpic = (action$: Observable<ActionWeaklyTyped>) => (
  action$
    .filter(action => action.type === 'ANALYTICS:TRACK_EVENT')
    .map((action) => {
      const { action: action_name, category, label, value, ...other_values } = action.payload;

      gtag('event', action_name, {
        value,
        event_category: category,
        event_label: label,
        ...other_values
      });

      return action;
    })
    .filter(() => false)
);

// TODO
// Have sift and dataLayer based off the same ANALYTICS:TRACK actions as gtag
// At the moment, they can't be as they are called throughout the code base
// which means some actions would be tracked multiple times
export const trackAddToCart = (action$: Observable<ActionWeaklyTyped>) => (
  action$
    .filter(action => action.type === 'CART_ITEM:ADD')
    .mergeMap((action) => {
      const { product_grouping, variant, quantity } = action.payload;

      // Returns two, one for enhanced ecommerce, one for legacy as label/action switched
      const action_params = [{
        action: 'add_to_cart',
        label: _.get(action, 'meta.analytics.tracking_identifier'),
        items: [{
          ...helpers.getItemData(product_grouping, variant, quantity),
          quantity: quantity
        }]
      }, {
        category: 'AddToCart',
        action: _.get(action, 'meta.analytics.tracking_identifier'),
        label: _.get(action, 'meta.analytics.target'),
        items: [{
          ...helpers.getItemData(product_grouping, variant, quantity),
          quantity: quantity
        }]
      }];
      return action_params.map(params => analytics_actions.track(params));
    })
);

// This needs its own epic so it can be debounced
const trackAutocompleteSearches = (action$: Observable<ActionWeaklyTyped>) => {
  return action$
    .filter((action) => action.type === 'AUTOCOMPLETE:ATTEMPT')
    .debounceTime(1000)
    .mergeMap((action) => {
      const query = action.payload.query;

      return Rx.Observable.of(analytics_actions.track({
        category: 'autocomplete',
        action: 'enter_query',
        label: query
      }));
    });
};

// Analytics Mapper Epics
type ActionMap = {
  [action: string]: (ActionWeaklyTyped, Object) => TrackActionParams
};

const GENERIC_ACTION_MAPPERS: ActionMap = {
  // 'CART_ITEM:ADD': See trackAddToCart epic above
  'CART_ITEM:REMOVE': (action) => ({
    action: 'remove_from_cart',
    items: [{
      id: action.meta.id
    }]
  }),
  'CART_ITEM:UPDATE_QUANTITY': (action, state) => {
    const cart_item: CartItem = findCartItem(state, action.meta.id); // meta.id === cart_item.id
    const is_increase = action.meta.analytics.previous_quantity < action.payload.quantity;

    return Rx.Observable.of(analytics_actions.track({
      action: is_increase ? 'add_to_cart' : 'remove_from_cart',
      items: [{
        ...helpers.getItemData(cart_item.product_grouping, cart_item.variant, action.payload.quantity),
        quantity: action.payload.quantity
      }]
    }));
  },

  'UI:VIEW_CONTENT': (action) => ({
    action: 'view_content',
    product_grouping_id: action.meta.product_grouping_id
  }),

  'EMAIL_CAPTURE:SHOW_EMAIL_CAPTURE_MODAL': (_action) => ({
    category: 'Email Capture Modal',
    action: 'Open'
  }),
  'EMAIL_CAPTURE:HIDE_EMAIL_CAPTURE_MODAL': (action) => ({
    category: 'Email Capture Modal',
    action: 'Close',
    label: _.get(action, 'meta.analytics.target')
  }),
  'EMAIL_CAPTURE:PREVENT_EMAIL_CAPTURE_MODAL': (action) => ({
    category: 'Email Capture Modal',
    action: 'Prevent',
    label: _.get(action, 'meta.analytics.target')
  }),
  'EMAIL_CAPTURE:ADD_EMAIL__SUCCESS': (action) => ({
    category: action.meta.analytics.target || 'Email Capture Modal',
    action: 'Email Submitted',
    label: _.get(action, 'payload.account_exists') ? 'existing_user' : 'new_user'
  }),
  'EMAIL_CAPTURE:COPY_COUPON': (action) => ({
    category: 'Email Capture Modal',
    action: 'Coupon Copied',
    label: _.get(action, 'payload.coupon_code')
  }),

  'SUPPLIER:SWAP_CURRENT_SUPPLIER': (action) => {
    const new_supplier_id = Object.keys(action.payload.swap_map)[0];
    return {
      category: 'switch_supplier',
      action: new_supplier_id,
      label: action.meta.analytics.target
    };
  },

  'PRODUCT_LIST:SET_SORT': (action) => ({
    category: 'sort_plp',
    action: action.payload.sort_option_id
  }),
  'PRODUCT_LIST:SET_FILTER': (action) => ({
    category: 'filter_plp',
    ...helpers.stringifyFilter(action.payload.filter),
    filter: action.payload.filter // unconsumed by GA
  })
};

const makeGoogleAnalyticsEpic = (getTrackingData: (ActionWeaklyTyped, Object) => TrackActionParams, key: string) => (
  (action$: Observable<ActionWeaklyTyped>, store: Object) => (
    action$
      .filter(action => action.type === key)
      .mergeMap(action => {
        const state = store.getState();
        const action_params = getTrackingData(action, state);
        return _.isArray(action_params)
          ? action_params.map(params => analytics_actions.track(params))
          : Rx.Observable.of(analytics_actions.track(action_params));
      })
  )
);

const googleAnalyticsEpics = _.mapValues(GENERIC_ACTION_MAPPERS, makeGoogleAnalyticsEpic);

export default {
  googleAnalyticsRootEpic,
  trackAddToCart,
  trackAutocompleteSearches,
  trackCheckoutSteps,
  trackPageViews,
  trackVirtualPageViews,
  trackPurchase,
  ...googleAnalyticsEpics
};
