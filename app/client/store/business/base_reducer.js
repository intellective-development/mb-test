// @flow

import { combineReducers } from 'redux';
import { connectRouter } from 'connected-react-router';

import addressReducer from './address/reducer';
import autocompleteReducer from './autocomplete/reducer';
import cartItemReducer from './cart_item/reducer';
import cartShareReducer from './cart_share/reducer';
import contentLayoutReducer from './content_layout/reducer';
import contentModuleReducer from './content_module/reducer';
import deliveryMethodReducer from './delivery_method/reducer';
import emailCaptureReducer from './email_capture/reducer';
import externalProductReducer from './external_product/reducer';
import filterReducer from './filter/reducer';
import requestStatusReducer from './request_status/reducer';
import paymentProfileReducer from './payment_profile/reducer';
import productListReducer from './product_list/reducer';
import productGroupingReducer from './product_grouping/reducer';
import schedulingCalendarReducer from './scheduling_calendar/reducer';
import searchSwitchReducer from './search_switch/reducer';
import sessionReducer from './session/reducer';
import supplierReducer from './supplier/reducer';
import UIReducer from './ui/reducer';
import userReducer from './user/reducer';
import variantReducer from './variant/reducer';
import cocktails from './cocktails';
import workingHoursReducer from './working_hours/reducer';
import checkout from '../../modules/checkout/checkout.dux';
import history from '../../shared/utils/history';
import product_browse from '../../product_browse/product_browse.dux';

const routerReducer = connectRouter(history);

const baseReducer = combineReducers({
  router: routerReducer,
  address: addressReducer,
  autocomplete: autocompleteReducer,
  cart_item: cartItemReducer,
  cart_share: cartShareReducer,
  checkout,
  cocktails,
  content_layout: contentLayoutReducer,
  content_module: contentModuleReducer,
  delivery_method: deliveryMethodReducer,
  email_capture: emailCaptureReducer,
  external_product: externalProductReducer,
  filter: filterReducer,
  request_status: requestStatusReducer,
  payment_profile: paymentProfileReducer,
  product_browse,
  product_list: productListReducer,
  product_grouping: productGroupingReducer,
  scheduling_calendar: schedulingCalendarReducer,
  search_switch: searchSwitchReducer,
  session: sessionReducer,
  supplier: supplierReducer,
  ui: UIReducer,
  user: userReducer,
  variant: variantReducer,
  working_hours: workingHoursReducer
});

export default baseReducer;
