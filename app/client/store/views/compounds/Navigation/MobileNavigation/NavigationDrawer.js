// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { ui_actions } from 'store/business/ui';
import { user_selectors } from 'store/business/user';
import type { User } from 'store/business/user';

import DeliveryInfo from '../shared/DeliveryInfo';
import { MBAppStoreLink, MBDrawer, MBDynamicIcon, MBLink, MBText, MBTouchable } from '../../../elements';
import styles from './NavigationDrawer.scss';

type NavigationDrawerProps = {
  show: boolean,
  closeDrawer: () => void,

  // Connect Props
  user: User,
  showDeliveryInfoModal: () => void,
  showHelpModal: () => void
};
const NavigationDrawer = ({show, closeDrawer, user, showDeliveryInfoModal, showHelpModal}: NavigationDrawerProps) => {
  return (
    <MBDrawer
      open={show}
      closeDrawer={closeDrawer}
      className={styles.cmMNavDrawer_Container}>
      <div className={styles.cmMNavDrawer_Content}>
        <CloseLink handleClick={closeDrawer} />
        <DeliveryLink showDeliveryInfoModal={showDeliveryInfoModal} closeDrawer={closeDrawer} />
        <NavigationLinks user={user} closeDrawer={closeDrawer} showHelpModal={showHelpModal} />
        <MBAppStoreLink className={styles.cmMNavDrawer_AppStoreLink} />
      </div>
    </MBDrawer>
  );
};

const CloseLink = ({handleClick}) => (
  <MBTouchable onClick={handleClick}>
    <MBDynamicIcon name="x_close" width={30} height={30} className={styles.cmMNavDrawer_CloseLink} />
  </MBTouchable>
);

const DeliveryLink = ({showDeliveryInfoModal, closeDrawer}) => (
  <MBTouchable
    role="button"
    className={styles.cmMNavDrawer_DeliveryLink}
    onClick={() => {
      showDeliveryInfoModal();
      closeDrawer();
    }} >
    <DeliveryInfo />
    <MBDynamicIcon name="chevron_right" width={28} height={28} />
  </MBTouchable>
);

const NavigationLinks = ({user, closeDrawer, showHelpModal}) => (
  <ul className={styles.cmMNavDrawer_ItemLinkContainer}>
    <li>
      <MBLink.Text
        href="/store/"
        beforeNavigate={closeDrawer}
        className={styles.cmMNavDrawer_ItemLink}
        standard={false}>
        Shop
      </MBLink.Text>
    </li>
    <li>
      <MBLink.Text
        href="/referrals"
        className={styles.cmMNavDrawer_ItemLink}
        native_behavior
        standard={false}>
        Share & Save $10
      </MBLink.Text>
    </li>
    <li>
      <MBLink.Text
        href="/account/orders"
        className={styles.cmMNavDrawer_ItemLink}
        native_behavior
        standard={false}>
        Orders
      </MBLink.Text>
    </li>
    <li>
      <MBLink.Text
        href="/account/overview"
        className={styles.cmMNavDrawer_ItemLink}
        native_behavior
        standard={false}>
        Account
        <MBText.Span className={styles.cmMNavDrawer_UserName}>
          &emsp;{user && `${user.first_name} ${user.last_name.slice(0, 1)}.`}
        </MBText.Span>
      </MBLink.Text>
    </li>
    <li>
      <MBTouchable
        className={styles.cmMNavDrawer_ItemLink}
        onClick={() => {
          closeDrawer();
          showHelpModal();
        }} >
        <MBText.Span>Help</MBText.Span>
      </MBTouchable>
    </li>
  </ul>
);

const NavigationDrawerSTP = () => {
  const findUser = Ent.find('user');

  return (state) => ({user: findUser(state, user_selectors.currentUserId(state))});
};
const NavigationDrawerDTP = {
  showDeliveryInfoModal: ui_actions.showDeliveryInfoModal,
  showHelpModal: ui_actions.showHelpModal
};
const NavigationDrawerContainer = connect(NavigationDrawerSTP, NavigationDrawerDTP)(NavigationDrawer);

export default NavigationDrawerContainer;
