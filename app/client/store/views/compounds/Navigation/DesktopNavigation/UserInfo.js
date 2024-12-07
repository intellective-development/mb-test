// @flow

import * as React from 'react';
import * as Ent from '@minibar/store-business/src/utils/ent';
import I18n from 'store/localization';
import { connect } from 'react-redux';
import bindClassNames from 'shared/utils/bind_classnames';
import { ui_actions } from 'store/business/ui';
import { user_selectors } from 'store/business/user';
import { working_hours_actions } from 'store/business/working_hours';
import type { User } from 'store/business/user';

import { MBClickOutside, MBLink, MBText, MBIcon, MBTouchable } from '../../../elements';
import styles from './UserInfo.scss';

const cn = bindClassNames(styles);

type ToggleContainerProps = {
  onClick: () => void,
  user_fetching: boolean,
  menu_visible: boolean,
  children: React.Node
};
type UserInfoProps = {|
  user?: User,
  user_fetching: boolean,
  showHelpModal: () => void,
  fetchWorkingHours: () => void,
  menuClassName?: string,
  ToggleContainer?: React.ComponentType<ToggleContainerProps>
|};
type UserInfoState = {|
  menu_visible: boolean
|};
class UserInfo extends React.Component<UserInfoProps, UserInfoState> {
  state = { menu_visible: false }

  componentDidMount(){
    this.props.fetchWorkingHours();
  }

  toggleMenuVisiblity = () => {
    this.setState((prev_state) => ({menu_visible: !prev_state.menu_visible}));
  }

  hideMenu = () => {
    this.setState({menu_visible: false});
  }

  render(){
    const { user, user_fetching, showHelpModal, menuClassName, ToggleContainer } = this.props;
    const { menu_visible } = this.state;

    return (
      <MBClickOutside handleClickOutside={this.hideMenu} disableOnClickOutside={!menu_visible} >
        <div className={styles.cmUserInfo_Wrapper}>
          <UserInfoMenuToggle
            user={user}
            user_fetching={user_fetching}
            menu_visible={menu_visible}
            toggleMenuVisiblity={this.toggleMenuVisiblity}
            Container={ToggleContainer} />
          <UserMenu
            user={user}
            user_fetching={user_fetching}
            menu_visible={menu_visible}
            showHelpModal={showHelpModal}
            menuClassName={menuClassName} />
        </div>
      </MBClickOutside>
    );
  }
}

const UserInfoMenuToggle = ({user, user_fetching, menu_visible, toggleMenuVisiblity, Container = NavToggleContainer}) => {
  const classes = cn('cmUserInfo_Prompt', {cmUserInfo_Prompt__Loading: user_fetching});

  return (
    <Container
      onClick={toggleMenuVisiblity}
      user_fetching={user_fetching}
      menu_visible={menu_visible} >
      <MBText.Span className={classes}>{userPrompt(user)}</MBText.Span>
      <MBIcon
        name="down_arrow_red"
        className={cn('cmUserInfo_DiscloseIcon', {cmUserInfo_DiscloseIcon_Active: menu_visible})} />
    </Container>
  );
};
const NavToggleContainer = ({user_fetching, onClick, menu_visible, children}: ToggleContainerProps) => {
  // we only a assign the id if this is actually usable as a toggle
  // this id is used to facilitate integration testing
  const menu_toggle_id = user_fetching ? '' : 'user-menu-toggle';

  return (
    <MBTouchable
      onClick={onClick}
      id={menu_toggle_id}
      className={cn('cmUserInfo_PromptContainer', {cmUserInfo_PromptContainer__DropdownVisible: menu_visible})}>
      {children}
    </MBTouchable>
  );
};

const UserMenu = ({user, showHelpModal, menu_visible, menuClassName}) => {
  if (user){
    return <SignedInMenu is_visible={menu_visible} showHelpModal={showHelpModal} className={menuClassName} />;
  } else {
    return <SignedOutMenu is_visible={menu_visible} showHelpModal={showHelpModal} className={menuClassName} />;
  }
};

const SignedInMenu = ({is_visible, showHelpModal, className}) => (
  <ul className={cn('cmUserInfo_Menu', className, {cmUserInfo_Menu__Invisible: !is_visible})}>
    <li>
      <MBLink.Text
        href="/referrals"
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}
        native_behavior
        standard={false}>
        Share & Earn $10
      </MBLink.Text>
    </li>
    <li>
      <MBLink.Text
        href="/account/orders"
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}
        native_behavior
        standard={false}>
        Orders
      </MBLink.Text>
    </li>
    <li>
      <MBLink.Text
        href="/account/overview"
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}
        native_behavior
        standard={false}>
        Account
      </MBLink.Text>
    </li>
    <li>
      <MBTouchable
        onClick={showHelpModal}
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}>
        <MBText.Span>Help</MBText.Span>
      </MBTouchable>
    </li>
    <li className={cn('cmUserInfo_Menu_LinkDivider')} />
    <li>
      <MBLink.Text
        href="/logout"
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Secondary')}
        native_behavior
        standard={false}>
        Sign Out
      </MBLink.Text>
    </li>
  </ul>
);

const SignedOutMenu = ({is_visible, showHelpModal, className}) => (
  <ul className={cn('cmUserInfo_Menu', className, {cmUserInfo_Menu__Invisible: !is_visible})}>
    <li>
      <MBLink.Text
        href="/login"
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}
        native_behavior
        standard={false}>
        Log In
      </MBLink.Text>
    </li>
    <li>
      <MBLink.Text
        href="/signup"
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}
        native_behavior
        standard={false}>
        Create Account
      </MBLink.Text>
    </li>
    <li>
      <MBTouchable
        onClick={showHelpModal}
        className={cn('cmUserInfo_Menu_Link', 'cmUserInfo_Menu_Link__Primary')}>
        <MBText.Span>Help</MBText.Span>
      </MBTouchable>
    </li>
  </ul>
);

const userPrompt = (user) => {
  if (user){
    return I18n.t('ui.nav.user_info.prompt_logged_in', {first_name: user.first_name});
  } else {
    return I18n.t('ui.nav.user_info.prompt_logged_out');
  }
};

const UserInfoSTP = () => {
  const findUser = Ent.find('user');

  return (state) => ({
    user: findUser(state, user_selectors.currentUserId(state)),
    user_fetching: user_selectors.isFetching(state)
  });
};
const UserInfoDTP = {
  showHelpModal: ui_actions.showHelpModal,
  fetchWorkingHours: working_hours_actions.fetchWorkingHours
};
const UserInfoContainer = connect(UserInfoSTP, UserInfoDTP)(UserInfo);

export default UserInfoContainer;
