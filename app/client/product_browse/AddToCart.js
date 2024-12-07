// @flow

import * as React from 'react';
import _ from 'lodash';
import Rx from 'rxjs';
import { connect } from 'react-redux';
import { cart_item_actions, cart_item_selectors, cart_item_helpers } from 'store/business/cart_item';
import type { Variant } from 'store/business/variant';
import type { ProductGrouping } from 'store/business/product_grouping';
import classNames from 'classnames';
import addShippingWarning from './AddShippingWarning';
import addSplitDeliveryWarning from './AddSplitDeliveryWarning';
import { MBTouchable } from '../store/views/elements';

const { validateQuantity } = cart_item_helpers;

const SHOW_DEFAULT_DELAY = 2400;

const generateLifecycleStream = function(){
  // TODO: is there a better way to emit values to a stream over time?
  const to_added = Rx.Observable.of('added');
  const to_default_timer = Rx.Observable.of('default').delay(SHOW_DEFAULT_DELAY);
  return Rx.Observable.merge(to_added, to_default_timer);
};

type AbleToAddProps = {
  variant: Variant,
  cartItems: Object,
  product_grouping: ProductGrouping,
  quantity: number,
  className: string,
  handleLifecycleChange: (string) => void,
  tracking_identifier: string,
  addCartItem: typeof cart_item_actions.addCartItem,
  target?: 'homepage' | 'pdp_main' | 'pdp_you_may_also_like' | 'plp' | 'checkout_you_may_also_like' | string
};
type AbleToAddState = { buttonLifecycleState: string }; // TODO: change to enum and snake case
// exported for non-standard add to cart situations
// This higher order component will handle firing the add to cart event, and will feed a lifecycle string
// To its wrapped component, that that component can use to modify its styles and/or content.
export const makeComponentAbleToAdd = (WrappedComponent) => {
  class AbleToAddComponent extends React.Component<AbleToAddProps, AbleToAddState> {
    static defaultProps = {
      quantity: 1,
      className: 'button add-to-cart',
      handleLifecycleChange: () => {}
    };

    button_clicked: Object
    lifecycle_subscription: any

    constructor(props){
      super(props);
      this.button_clicked = new Rx.Subject();
      this.state = {buttonLifecycleState: 'default'};
      this.lifecycle_subscription = this.button_clicked
        .switchMap(generateLifecycleStream)
        .subscribe((buttonLifecycleState) => {
          this.setState({buttonLifecycleState});
          this.props.handleLifecycleChange(buttonLifecycleState);
        });
    }

    componentWillUnmount(){
      this.lifecycle_subscription.unsubscribe();
    }

    addToCart = () => {
      const { variant, product_grouping, quantity, tracking_identifier, target } = this.props;
      this.button_clicked.next(true);
      const valid_quantity = validateQuantity(parseInt(quantity), variant.in_stock);
      this.props.addCartItem(product_grouping, variant, valid_quantity, { tracking_identifier, target });
      return false; //otherwise, the click event will propogate up to the containing link
    };
    render(){
      const { cartItems, variant } = this.props;
      const { quantity } = _.head(_.filter(cartItems, { variant: variant.id })) || {};
      const disabled = quantity >= variant.in_stock;
      return <WrappedComponent {...this.props} {...this.state} disabled={disabled} addToCart={this.addToCart} />;
    }
  }

  const AbleToAddComponentDTP = {addCartItem: cart_item_actions.addCartItem};
  const AbleToAddComponentSTP = state => ({ cartItems: cart_item_selectors.getAllCartItems(state) });
  return connect(AbleToAddComponentSTP, AbleToAddComponentDTP)(AbleToAddComponent);
};

// normal button

const getButtonText = (button_lifecycle_state, disabled) => {
  const addToCartText = disabled ? 'No more items in stock' : 'Add to Cart';
  return button_lifecycle_state === 'added' ? '\u2713 In Cart' : addToCartText;
};

const getButtonStateClass = (button_lifecycle_state) => (
  button_lifecycle_state === 'added' ? 'button--bright-red' : ''
);

const AddToCartButton = ({className, buttonLifecycleState, disabled, addToCart}) => {
  const button_content = getButtonText(buttonLifecycleState, disabled);
  const button_classes = classNames(className, getButtonStateClass(buttonLifecycleState));
  const disabledStyle = disabled ? { backgroundColor: 'grey' } : {};

  return <MBTouchable style={disabledStyle} disabled={disabled} className={button_classes} onClick={addToCart}>{button_content}</MBTouchable>;
};

export default makeComponentAbleToAdd(addSplitDeliveryWarning(addShippingWarning(AddToCartButton)));
