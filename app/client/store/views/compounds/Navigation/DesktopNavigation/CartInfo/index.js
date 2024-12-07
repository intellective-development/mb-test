// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import * as Ent from '@minibar/store-business/src/utils/ent';
import bindClassNames from 'shared/utils/bind_classnames';
import type { CartItem } from 'store/business/cart_item';
import { cart_share_selectors } from 'store/business/cart_share';
import { cart_item_selectors } from 'store/business/cart_item';
import { request_status_constants } from 'store/business/request_status';

import { MBDynamicIcon, MBLink } from '../../../../elements';
import CartDropdown from './CartDropdown';
import CartCountIndicator from '../../shared/CartCountIndicator';
import styles from './index.scss';

const cn = bindClassNames(styles);

const { LOADING_STATUS, PENDING_STATUS } = request_status_constants;

const SHOW_FOR_CART_DURATION = 2400;
const HOVER_OUT_DURATION = 200;

type CartInfoProps = {
  cart_items: Array<CartItem>,
  location: { pathname: String },
  is_updating: boolean
};
type CartInfoState = {|
  hovered_in: boolean,
  cart_recently_updated: boolean
|};
class CartInfo extends React.Component<CartInfoProps, CartInfoState> {
  state = {hovered_in: false, cart_recently_updated: false}
  static defaultProps = { cart_items: [] }

  cart_changed_hide_timeout: ?number
  hover_out_hide_timeout: ?number

  componentWillReceiveProps(next_props){
    if (!_.isEqual(this.props.cart_items, next_props.cart_items) && !this.props.is_updating && !next_props.is_updating){
      clearTimeout(this.cart_changed_hide_timeout);
      this.cart_changed_hide_timeout = undefined;

      this.setState({cart_recently_updated: true});
      this.cart_changed_hide_timeout = setTimeout(() => {
        this.setState({cart_recently_updated: false});
      }, SHOW_FOR_CART_DURATION);
    }
  }

  handleHoverIn = () => {
    clearTimeout(this.hover_out_hide_timeout);
    this.hover_out_hide_timeout = undefined;

    this.setState({hovered_in: true, cart_recently_updated: false});
  }

  handleHoverOut = () => {
    clearTimeout(this.hover_out_hide_timeout);
    this.hover_out_hide_timeout = undefined;

    this.hover_out_hide_timeout = setTimeout(() => {
      this.setState({hovered_in: false, cart_recently_updated: false});
    }, HOVER_OUT_DURATION);
  }

  render(){
    const { cart_items, location } = this.props;
    const path = location.pathname;
    const on_page_where_hidden = _.includes(path, '/cart') || _.includes(path, '/checkout');
    const dropdown_is_hidden = (!this.state.hovered_in && !this.state.cart_recently_updated) || on_page_where_hidden;

    return (
      <div
        onMouseEnter={this.handleHoverIn}
        onMouseLeave={this.handleHoverOut}
        className={styles.cmDNavCart_Container}>
        <MBLink.View
          href="/store/cart"
          className={cn('cmDNavCart_Link', {cmDNavCart_Link__DropdownVisible: !dropdown_is_hidden})}>
          <MBDynamicIcon name="cart_desktop" width={40} height={34} />
          <CartCountIndicator className={styles.cmDNavCart_CountInd} />
        </MBLink.View>
        <CartDropdown cart_items={cart_items} is_hidden={dropdown_is_hidden} />
      </div>
    );
  }
}

const CartInfoSTP = () => {
  const findCartItem = Ent.query(Ent.find('cart_item'), Ent.join('variant'), Ent.join('product_grouping'));
  return (state) => {
    const cart_id = cart_item_selectors.getCartId(state);
    const cart_share_id = cart_share_selectors.getCurrentCartShareId(state);
    const is_cart_fetching = [LOADING_STATUS, PENDING_STATUS].includes(cart_item_selectors.getFetchCartStatus(state, cart_id));
    const is_cart_share_applying = [LOADING_STATUS, PENDING_STATUS].includes(cart_share_selectors.getApplyCartShareStatus(state, cart_share_id));
    return {
      cart_items: findCartItem(state, cart_item_selectors.getAllCartItemIds(state)),
      is_updating: is_cart_fetching || is_cart_share_applying
    };
  };
};
const CartInfoContainer = connect(CartInfoSTP)(CartInfo);

export default withRouter(CartInfoContainer);
