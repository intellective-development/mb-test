import React from 'react';
import { withRouter } from 'react-router-dom';
import { ConnectedRouter } from 'connected-react-router';
import history from './history';

const ConnectedBrowserRouter = ({ children }) => (
  <ConnectedRouter history={history}>
    {children}
  </ConnectedRouter>
);

export default ConnectedBrowserRouter;

class ScrollToTopOnLocationChangeContainer extends React.Component {
  componentDidUpdate(prevProps){
    if (this.props.location !== prevProps.location){
      window.scrollTo(0, 0);
    }
  }

  render(){
    return this.props.children;
  }
}

export const ScrollToTop = withRouter(ScrollToTopOnLocationChangeContainer);
