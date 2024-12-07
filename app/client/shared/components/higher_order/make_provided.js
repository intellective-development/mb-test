// @flow

import * as React from 'react';
import { Provider } from 'react-redux';
import store from 'store/data_store';

// This HOC is a temporary stopgap while all of our react components are disconnected,
// and we'll need multiple providers at the top level.
//
// Down the line, we'll be able to pull this out and just have a single Provider at the top level,
// which should also be able to instantiate the store.

const makeProvided = (Component: React.ComponentType<*>) => {
  const Provided = (props: Object) => (
    <Provider store={store}>
      <Component {...props} />
    </Provider>
  );

  return Provided;
};

// this component exposes a more standard Provider component, useful for scenarios where the children
// can receive their own props without them needing to go through the Provider component.
export const MBProvider = (props: Object) => {
  return <Provider store={store} {...props} />;
};

export default makeProvided;
