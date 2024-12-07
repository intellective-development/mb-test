// @flow

import * as React from 'react';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { connect } from 'react-redux';
import { user_selectors } from 'store/business/user';
import type { User } from 'store/business/user';

import { MBButton, MBLink } from '../../../elements';
import UserInfo from '../../../compounds/Navigation/DesktopNavigation/UserInfo';
import ContactUs from '../../../compounds/Navigation/shared/ContactUs';
import styles from './index.scss';

type AccountInfoProps = {|
  user?: User,
  user_fetching: boolean
|};

const AccountInfo = ({user, user_fetching}: AccountInfoProps) => {
  return (
    <div className={styles.cmLandingHero_AccountContainer}>
      <AccountInfoContent user={user} user_fetching={user_fetching} />
      <ContactUs />
    </div>
  );
};

const AccountInfoContent = ({user, user_fetching}) => {
  if (user_fetching) return null;

  if (user){
    return (
      <UserInfo
        ToggleContainer={AccountInfoButton}
        menuClassName={styles.cmLandingHero_AccountInfoMenu} />
    );
  } else {
    return (
      <MBLink.View
        href="/login"
        native_behavior>
        <AccountInfoButton onClick={() => {}}>
          Log In
        </AccountInfoButton>
      </MBLink.View>
    );
  }
};

const AccountInfoButton = ({onClick, children}) => {
  return (
    <MBButton
      size="small"
      type="hollow"
      id="user-menu-toggle"
      onClick={onClick}
      className={styles.cmLandingHero_AccountInfoButton}>
      {children}
    </MBButton>
  );
};

const AccountInfoSTP = () => {
  const findUser = Ent.find('user');

  return (state) => ({
    user: findUser(state, user_selectors.currentUserId(state)),
    user_fetching: user_selectors.isFetching(state)
  });
};
const AccountInfoContainer = connect(AccountInfoSTP)(AccountInfo);

export default AccountInfoContainer;
