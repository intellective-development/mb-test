// @flow

import 'shared/polyfills';
import * as React from 'react';
import { createStore } from 'redux';
import { Provider } from 'react-redux';
import { LOADING_STATUS } from '@minibar/store-business/src/utils/fetch_status';

import baseReducer from './store/business/base_reducer';
import type { GlobalState } from './store/business/base_reducer';
import Navigation from './store/views/compounds/Navigation';
import StoreEntry from './store/views/compounds/StoreEntry';
import ProductScroller from './store/views/compounds/ProductScroller';
import {
  AppInstall as LandingAppInstall,
  LandingHero
} from './store/views/scenes/LandingPage';

const ServerProvider = (WrappedComponent: React.ComponentType<*>) => (initial_state: GlobalState) => {
  return (props: Object) => {
    // in the future, we may want to consider taking initial_state as a prop
    const store = createStore(baseReducer, initial_state);

    return (
      <Provider store={store}>
        <WrappedComponent {...props} />
      </Provider>
    );
  };
};

const BASE_LOADING_STATE = {
  user: {
    is_fetching: true
  },
  address: {
    fetch_status: LOADING_STATUS
  }
};

// make available on global scope, enables server-side rendering
window.LandingAppInstall = LandingAppInstall;
window.ProductScroller = ProductScroller;
window.StoreEntry = ServerProvider(StoreEntry)({});

// we simulate a loading state for delivery and user placements
window.Navigation = ServerProvider(Navigation)(BASE_LOADING_STATE);
window.LandingHero = ServerProvider(LandingHero)(BASE_LOADING_STATE);
