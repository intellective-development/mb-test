// @flow

import type { Action } from '@minibar/store-business/src/constants';

/*

THINK TWICE BEFORE YOU ADD THINGS HERE.
This is not a file for all actions being triggered BY the ui,
it's intended for actions targeted SOLELY AT the ui, specifically,
its reducer.

When NOT to put the action here:
1. The UI is firing an event to other parts of the state
2. The UI state is updated as a side effect of an update to a different part of the state.

If you're looking to write an action for either of those cases, look elsewhere.

*/

export const dismissCartShareDiff = (): Action => ({
  type: 'UI:DISMISS_CART_SHARE_DIFF'
});


export const showHelpModal = (): Action => ({
  type: 'UI:SHOW_HELP_MODAL'
});
export const hideHelpModal = (): Action => ({
  type: 'UI:HIDE_HELP_MODAL'
});

export const showDeliveryInfoModal = (destination: ?string = null): Action => ({
  type: 'UI:SHOW_DELIVERY_INFO_MODAL',
  payload: { destination }
});
export const hideDeliveryInfoModal = (): Action => ({
  type: 'UI:HIDE_DELIVERY_INFO_MODAL'
});

export const showSupplierMapModal = (supplier_id: number): Action => ({
  type: 'UI:SHOW_SUPPLIER_MAP_MODAL',
  payload: { supplier_id }
});
export const hideSupplierMapModal = (): Action => ({
  type: 'UI:HIDE_SUPPLIER_MAP_MODAL'
});

export const viewContent = (product_grouping_id: string): Action => ({
  type: 'UI:VIEW_CONTENT',
  meta: {
    product_grouping_id
  }
});
