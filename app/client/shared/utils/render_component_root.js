// @flow

import * as React from 'react';
import ReactDOM from 'react-dom';
import { AppContainer } from 'react-hot-loader';
import { MBProvider } from '../components/higher_order/make_provided';
import ConnectedBrowserRouter, { ScrollToTop } from './connected_browser_router';

// this is a wrapper around ReactDOM to help us enable react hot loading
// should pull out when we have one unified React root

const renderComponentRoot = (content: React.Node, ...rest_react_dom_args: Array<any>) => {
  ReactDOM.render(
    <AppContainer>
      <MBProvider>
        <ConnectedBrowserRouter>
          <ScrollToTop>
            {content}
          </ScrollToTop>
        </ConnectedBrowserRouter>
      </MBProvider>
    </AppContainer>,
    ...rest_react_dom_args
  );
};

export default renderComponentRoot;
