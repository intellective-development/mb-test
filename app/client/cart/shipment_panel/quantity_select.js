// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { cart_item_actions, cart_item_helpers } from 'store/business/cart_item';

const MAX_QUANTITY_DEFAULT = 24;
const REMOVE_ZERO_QUANTITY_DELAY = 2000;

const UpdateCartDTP = {
  updateCartItemQuantity: cart_item_actions.updateCartItemQuantity,
  removeCartItem: cart_item_actions.removeCartItem
};
const connectToUpdateCart = connect(null, UpdateCartDTP);

type MobileQuantitySpinnerProps = {
  quantity: number,
  cart_item_id: string,
  in_stock: number,
  warnRemoval: () => void,
  clearWarning: () => void,
  updateCartItemQuantity: typeof cart_item_actions.updateCartItemQuantity,
  removeCartItem: typeof cart_item_actions.removeCartItem
};
class MobileQuantitySpinner extends React.Component<MobileQuantitySpinnerProps> {
  remove_zero_quantity_timeout: ?number

  tryQuantityUpdate = (desired_quantity) => {
    const {cart_item_id, in_stock, warnRemoval, clearWarning, quantity, updateCartItemQuantity, removeCartItem} = this.props;
    const valid_quantity = cart_item_helpers.validateQuantity(parseInt(desired_quantity), in_stock);
    if (desired_quantity === 0){
      warnRemoval();
      this.remove_zero_quantity_timeout = setTimeout(() => {
        removeCartItem(cart_item_id);
      }, REMOVE_ZERO_QUANTITY_DELAY);
    } else if (this.remove_zero_quantity_timeout){
      clearWarning();
      clearTimeout(this.remove_zero_quantity_timeout); // allow user to save item during delayed removal
      this.remove_zero_quantity_timeout = undefined;
    } else {
      updateCartItemQuantity(cart_item_id, valid_quantity, quantity);
    }
  }

  render(){
    const {quantity} = this.props;
    return (
      <div className="number-spinner number-spinner--vertical">
        <button className="button grey number-spinner__button" onClick={() => this.tryQuantityUpdate(quantity + 1)}>+</button>
        <span className="number-spinner__value">{quantity}</span>
        <button className="button grey number-spinner__button" onClick={() => this.tryQuantityUpdate(quantity - 1)}>-</button>
      </div>
    );
  }
}

const MobileQuantitySpinnerContainer = connectToUpdateCart(MobileQuantitySpinner);
export {MobileQuantitySpinnerContainer as MobileQuantitySpinner};

type QuantitySelectProps = {
  quantity: number,
  cart_item_id: string,
  in_stock: number,
  updateCartItemQuantity: typeof cart_item_actions.updateCartItemQuantity
};
const QuantitySelect = ({quantity, cart_item_id, in_stock, updateCartItemQuantity}: QuantitySelectProps) => {
  const renderQuantityOptions = () => {
    const max_quantity = Math.min(in_stock, MAX_QUANTITY_DEFAULT) + 1; // +1 because _.range is exclusive
    let quantity_range = _.range(1, max_quantity);
    if (quantity >= max_quantity){ // add the current one to dropdown even if too large
      quantity_range = quantity_range.concat(quantity);
    }
    return quantity_range.map(quantity_option => (
      <option value={quantity_option} key={quantity_option}>{quantity_option}</option>
    ));
  };

  return (
    <select
      className="select--brand select--cart"
      name="quantity"
      value={quantity}
      onChange={e => updateCartItemQuantity(cart_item_id, parseInt(e.target.value), quantity)} >
      {renderQuantityOptions()}
    </select>
  );
};

const QuantitySelectContainer = connectToUpdateCart(QuantitySelect);
export {QuantitySelectContainer as QuantitySelect};
