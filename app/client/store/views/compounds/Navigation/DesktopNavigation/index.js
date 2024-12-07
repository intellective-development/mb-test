// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { user_selectors } from 'store/business/user';
import { analytics_actions } from 'store/business/analytics';

import { MBButton, MBLink, MBIcon, MBLayout } from '../../../elements';
import BrowseBar from './BrowseBar';
import DeliveryLink from './DeliveryLink';
import UserInfo from './UserInfo';
import CartInfo from './CartInfo';
import CheckoutBreadcrumbs from './CheckoutBreadcrumbs';

import styles from './index.scss';

type DesktopNavigationProps = {|
  is_checking_out: boolean,
  trackReorder(): void
|}
class DesktopNavigation extends React.Component<DesktopNavigationProps> {
  renderCheckoutContent = () => {
    return (
      <MBLayout.StandardGrid className={styles.cmDNav_ContainerCheckout} no_padding>
        <MBLogo />
        <CheckoutBreadcrumbs />
      </MBLayout.StandardGrid>
    );
  }

  renderBrowseContent = () => {
    return (
      <MBLayout.StandardGrid className={styles.cmDNav_ContainerBrowse} no_padding>
        <MBLogo />
        <header className={styles.cmDNav_Content}>
          <div className={styles.cmDNav_TopBar}>
            <div className={styles.cmDNav_TopBar_Left}>
              <DeliveryLink />
            </div>
            <div className={styles.cmDNav_TopBar_Right}>
              <UserInfo />
              <ReorderButtonContainer trackReorder={this.props.trackReorder} />
              <CartInfo />
            </div>
          </div>
          <BrowseBar />
        </header>
      </MBLayout.StandardGrid>
    );
  }

  render(){
    const { is_checking_out } = this.props;
    const content = is_checking_out ? this.renderCheckoutContent() : this.renderBrowseContent();

    return (
      <div className={styles.cmDNav_FullScreenWrapper}>
        {content}
      </div>
    );
  }
}

const MBLogo = () => {
  return (
    <a
      id="logo"
      title="Minibar Delivery"
      className={styles.cmDNav_NavLogo_Container}
      href="/store/">
      <MBIcon name="minibar_logo" className={styles.cmDNav_NavLogo} />
    </a>
  );
};

const ReorderButton = ({ user, trackReorder }) => {
  if (!user || user.order_count < 1) return null;
  return (
    <div className={styles.cmDNav_ReorderContainer}>
      <MBLink.View href="/store/products/previous-purchases">
        <MBButton
          size="small"
          type="hollow"
          className={styles.cmDNav_ReorderButton}
          onClick={trackReorder}>
          Quick Re-order
        </MBButton>
      </MBLink.View>
    </div>
  );
};
const ReorderButtonSTP = () => {
  const findUser = Ent.find('user');
  return (state) => ({user: findUser(state, user_selectors.currentUserId(state))});
};

const ReorderButtonDTP = {
  trackReorder: () => analytics_actions.track({ category: 'reorder', action: 'navigate to previous order page', label: 'store home' })
};
const ReorderButtonContainer = connect(ReorderButtonSTP, ReorderButtonDTP)(ReorderButton);

export default DesktopNavigation;
