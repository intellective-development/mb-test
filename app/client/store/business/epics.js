// @flow

import _ from 'lodash';

import { combineEpics } from 'redux-observable';
import { unbatchEpicActions } from '@minibar/store-business/src/utils/batching';

import address_epics from './address/epics';
import autocomplete_epics from './autocomplete/epics';
import analytics_epics from './analytics/epics';
import cart_item_epics from './cart_item/epics';
import cart_share_epics from './cart_share/epics';
import content_layout_epics from './content_layout/epics';
import email_capture_epics from './email_capture/epics';
import filter_epics from './filter/epics';
import legacy_link_epics from './legacy_link/epics';
import payment_profile_epics from './payment_profile/epics';
import product_grouping_epics from './product_grouping/epics';
import product_list_epics from './product_list/epics';
import session_epics from './session/epics';
import supplier_epics from './supplier/epics';
import scheduling_calendar_epics from './scheduling_calendar/epics';
import search_switch_epics from './search_switch/epics';
import ui_epics from './ui/epics';
import user_epics from './user/epics';
import working_hours_epics from './working_hours/epics';

// convert the imported epic objects into an array
const epics_by_module = [
  address_epics,
  autocomplete_epics,
  analytics_epics,
  cart_item_epics,
  cart_share_epics,
  content_layout_epics,
  email_capture_epics,
  filter_epics,
  legacy_link_epics,
  payment_profile_epics,
  session_epics,
  product_grouping_epics,
  product_list_epics,
  supplier_epics,
  scheduling_calendar_epics,
  search_switch_epics,
  ui_epics,
  user_epics,
  working_hours_epics
];

const epics = _.flatMap(epics_by_module, (module_epic_exports: Object): Array<Object> => {
  // we pull the actual epic functions out of the exports we received from the each file
  const module_epics = Object.keys(module_epic_exports).map(key => module_epic_exports[key]);

  // each epic is run through our unbatching helper, so they receive unbatched actions individually
  return module_epics.map(unbatchEpicActions);
});

const rootEpic = combineEpics(...epics);
export default rootEpic;
