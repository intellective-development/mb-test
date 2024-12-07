// @flow

import * as React from 'react';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { push } from 'connected-react-router';
import store from '../../data_store';

import * as MBText from './MBText';

type MBLinkProps = {
  href?: string,
  disabled?: boolean,
  native_behavior?: boolean,
  children: React.Node,
  beforeNavigate?: () => void
};

export const makeLink = (WrappedComponent: React.ComponentType<*>, display_name_base: string) => {
  class MBLink extends React.Component<MBLinkProps> {
    static displayName = `MBLink(${display_name_base})`

    static contextTypes = {
      router: PropTypes.shape({
        history: PropTypes.object.isRequired,
        route: PropTypes.object.isRequired,
        staticContext: PropTypes.object
      })
    };

    static childContextTypes = {
      router: PropTypes.object.isRequired
    };

    getChildContext(){
      return {
        router: this.context.router
      };
    }

    handleClick = (e: SyntheticEvent<HTMLAnchorElement>) => {
      const { href, disabled, native_behavior, beforeNavigate } = this.props;

      if (beforeNavigate) beforeNavigate();

      if (disabled || !href){
        // no javascript or browser action
        e.preventDefault();
        return false;
      } else if (native_behavior || isCompoundKeyboardClick(e) || isReferralLink(href) || isAccountLink(href)){
        // let the browser handle it
        return true;
      } else {
        e.preventDefault();
        store.dispatch(push(href));
        return false;
      }
    }

    render(){
      const native_props = _.omit(this.props, ['native_behavior', 'beforeNavigate']);

      const Component = <WrappedComponent {...native_props} onClick={this.handleClick} />;

      if (this.context.router){
        const ComponentWithRouter = withRouter(() => Component);
        return <ComponentWithRouter />;
      }

      return Component;
    }
  }

  return MBLink;
};

const MBLink = {
  // Renders a simple text link
  Text: makeLink(MBText.A, 'Text'),

  // Renders an unstyled link block
  // TODO: overwrite/undo foundation tag styles
  View: makeLink(props => <a {...props} />, 'View')
};

export default MBLink;

// check if it should have special keyboard shortcut behavior
function isCompoundKeyboardClick(e: SyntheticEvent<HTMLAnchorElement>){
  return e.metaKey || e.ctrlKey || e.shiftKey || e.altKey;
}

// TODO: LD: when we have account in store, rip this out.
// Is a special case of "isOutsideStoreLink"
function isReferralLink(url: string){
  return url === '/referrals';
}

function isAccountLink(url: string){
  return _.startsWith(url, '/account');
}

