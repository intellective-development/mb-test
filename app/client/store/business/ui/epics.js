// @flow

import type { Observable } from 'rxjs';
import type { ActionWeaklyTyped } from '@minibar/store-business/src/constants';
import { actionStream } from 'shared/dispatcher';
import { isExternallyNavigable, navigateTo } from 'legacy_store/router/utils';
import { address_selectors } from '../address';

import * as ui_actions from './actions';
import * as ui_utils from './utils';

const routeExternal = (_action$: Observable<ActionWeaklyTyped>, store: Object) => {
  return actionStream('navigate')
    .map(({destination, options}) => {
      let action = null;
      const is_external = !address_selectors.hasDeliveryAddress(store.getState());
      const is_externally_navigable = isExternallyNavigable(destination);

      if (is_external && !is_externally_navigable){ // if there is no delivery address present, and can't navigate, show the modal
        action = ui_actions.showDeliveryInfoModal(destination);
      } else if (window.Minibar){ // if we're in the store, navigate with it (window.Minibar === the router)
        navigateTo(destination, options);
      } else { // otherwise, enter it
        ui_utils.enterStore(destination);
      }
      return action;
    })
    .filter((action) => !!action);
};

const showDeliveryInfo = (action$: Observable<ActionWeaklyTyped>) => {
  return action$
    // when the store initializes, we dispatch a refresh suppliers action
    // we only care about the first such action
    .filter(action => action.type === 'SUPPLIER:REFRESH_SUPPLIERS__SUCCESS')
    .take(1)
    .filter(show_action => !!show_action); // filter out any null actions
};

export default {
  routeExternal,
  showDeliveryInfo
};
