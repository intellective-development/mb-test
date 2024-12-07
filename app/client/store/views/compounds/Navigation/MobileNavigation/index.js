// @flow
import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';

import { MBIcon, MBDynamicIcon, MBLink, MBTouchable } from '../../../elements';
import CartCountIndicator from '../shared/CartCountIndicator';
import NavigationDrawer from './NavigationDrawer';
import BrowseBar from './BrowseBar';
import styles from './index.scss';

const cn = bindClassNames(styles);

type MobileNavigationProps = {|
  is_checking_out: boolean
|}
type MobileNavigationState = {show_drawer: boolean};
class MobileNavigation extends React.Component<MobileNavigationProps, MobileNavigationState> {
  state = {show_drawer: false}

  showDrawer = () => {
    this.setState({show_drawer: true});
  }
  hideDrawer = () => {
    this.setState({show_drawer: false});
  }

  render(){
    const { is_checking_out } = this.props;

    return (
      <header className={styles.cmMNav_Container}>
        <div className={styles.cmMNav_Top}>
          <MenuButton onClick={this.showDrawer} is_hidden={is_checking_out} />
          <Logo />
          <CartInfo is_hidden={is_checking_out} />
        </div>
        <BottomBar is_hidden={is_checking_out} />
        <NavigationDrawer
          closeDrawer={this.hideDrawer}
          openDrawer={this.showDrawer}
          show={this.state.show_drawer} />
      </header>
    );
  }
}

const MenuButton = ({onClick, is_hidden}) => {
  if (is_hidden) return null;

  return (
    <MBTouchable
      onClick={onClick}
      className={cn('cmMNav_Top_Element', 'cmMNav_Top_Element_Left')}>
      <MBDynamicIcon name="hamburger" width={32} height={32} />
    </MBTouchable>
  );
};

const Logo = () => {
  return (
    <div className={cn('cmMNav_Top_Element', 'cmMNav_Top_Element_Center')}>
      <MBLink.View alt="home" href="/store/">
        <MBIcon name="mobile.minibar_logo" width="76" />
      </MBLink.View>
    </div>
  );
};

const CartInfo = ({is_hidden}) => {
  if (is_hidden) return null;

  return (
    <MBLink.View
      className={cn('cmMNav_Top_Element', 'cmMNav_Top_Element_Right')}
      href="/store/cart">
      <MBDynamicIcon name="cart_mobile" width={32} height={32} className={styles.cmMNav_CartIcon} />
      <CartCountIndicator className={styles.cmMNav_CartCount} />
    </MBLink.View>
  );
};

const BottomBar = ({is_hidden}) => {
  if (is_hidden) return null;

  return (
    <div className={styles.cmMNav_Bottom}>
      <BrowseBar />
    </div>
  );
};

export default MobileNavigation;
