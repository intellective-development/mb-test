// @flow

import React from 'react';
import _ from 'lodash';
import formatCurrency from 'shared/utils/format_currency';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { cart_item_helpers } from 'store/business/cart_item';
import { hasShopRunnerToken } from 'shared/utils/shop_runner';
import OrderAddToCart from '../../../../../product_browse/AddToCart';
import VariantPrice from './VariantPrice';
import { DealList } from '../ProductDetailElements';

type VariantItemProps = {
  productGrouping: ProductGrouping,
  shipping: String,
  variant: Variant
}
type VariantItemState = {
  quantity: number
}
class VariantItem extends React.PureComponent<VariantItemProps, VariantItemState> {
  // TODO: should default this to the quantity in cart, if any
  state = { quantity: 1 }

  setQuantity = (next_quantity) => {
    this.setState({ quantity: next_quantity });
  }

  render(){
    const { quantity } = this.state;

    const { cart_items, variant, selected, shipping } = this.props;
    const supplier = variant.supplier || null;
    const product_grouping = variant.productGrouping || null;
    const excludeDelivery = _.uniq(product_grouping.tags).includes('bartender');
    const inCart = (_.head(_.filter(cart_items, item => item && item.variant && item.variant.id === variant.id)) || {}).quantity || 0;
    const available = variant.in_stock - inCart;


    /*TODO: if (variant.in_stock <= 0){
      return <div className="column large-12"><p className="panel--pdp--message">Sorry, this product is out-of-stock.</p></div>;
    }*/

    return (
      <div
        className="store"
        itemProp="offers"
        itemScope
        itemType="https://schema.org/Offer">
        <DealList deals={_.union(product_grouping.deals, variant.deals)} />
        <div>
          <SupplierName {...supplier} />
          <VariantPrice variant={variant} />
        </div>
        <div>
          <SupplierStatus {...supplier} excludeDelivery={excludeDelivery} />
          <DeliveryFee
            {...supplier}
            excludeDelivery={excludeDelivery}
            price={variant.price} />
        </div>
        <DeliveryMinimum {...supplier} excludeDelivery={excludeDelivery} />
        { selected ? <div aria-expanded={selected}>
          <OrderQuantity
            available={available}
            current_variant={variant}
            handleChange={this.setQuantity}
            value={quantity} />
          <OrderAddToCart
            className="button add-to-cart order_add_to_cart"
            product_grouping={product_grouping}
            quantity={quantity}
            cart_items={cart_items}
            target="pdp_main"
            tracking_identifier="pdp_main"
            handleLifecycleChange={this.props.addToCardHandler}
            variant={variant}>
            Add to Cart
          </OrderAddToCart>
        </div> : null }
        { selected ? <div aria-expanded>
          <OrderMinimum
            cart_items={cart_items}
            excludeDelivery={excludeDelivery}
            shipping={shipping}
            supplier={supplier} />
        </div> : null }
      </div>
    );
  }
}

export default VariantItem;

const SupplierName = ({ name } /* : Supplier */) => (
  <div
    className="avenir_font supplier_name"
    itemProp="seller"
    itemScope
    itemType="https://schema.org/Organization">
    <span itemProp="name">{name}</span>
  </div>
);

/* eslint-disable no-irregular-whitespace */
const SupplierStatus = ({ deliveryMethods, excludeDelivery }) => {
  const isClosed = delivery_method_helpers.isClosed(deliveryMethods[0]);

  if (excludeDelivery){
    return null;
  }

  // Replaces all spaces with non-breaking spaces, except after a colon.
  const msg = delivery_method_helpers
    .formatNextDelivery(deliveryMethods[0], { include_type: true })
    .replace(/ /g, ' ')
    .replace(/: /, ': ');

  const deliveryLeadTime = _.get(
    _.head(deliveryMethods), 'maximum_delivery_expectation'
  );

  return (
    <span
      itemProp="deliveryLeadTime"
      itemScope
      itemType="https://schema.org/QuantitativeValue">
      {isClosed && (
        <span className="supplier_closed">Currently closed. </span>
      )}
      <span className="delivery_estimate">
        <meta content="MIN" itemProp="unitCode" />
        <span
          content={deliveryLeadTime}
          itemProp="maxValue">
          {msg}
        </span>
      </span>
    </span>
  );
};

const ShoprunnerLogo = () => {
  if (!hasShopRunnerToken()) return null;
  return (
    <div className={'_SRD'} style={{ display: 'inline-block', verticalAlign: 'middle', marginRight: '0.5em' }}>
      <div className={'srd_iconline'}>
        <div className="srd_logo" />
      </div>
    </div>
  );
};

const DeliveryFee = ({
  best_delivery_fee,
  excludeDelivery,
  deliveryMethods,
  price
}) => {
  if (excludeDelivery){
    return null;
  }

  const free_delivery_threshold = _.get(
    _.head(deliveryMethods), 'free_delivery_threshold'
  );

  return (
    <span
      className="delivery_fee"
      itemProp="priceSpecification"
      itemScope
      itemType="https://schema.org/PriceSpecification">
      <meta content="USD" itemProp="priceCurrency" />
      <span
        content={best_delivery_fee}
        itemProp="price">
        <ShoprunnerLogo />
        {
          best_delivery_fee === 0 || price > free_delivery_threshold || hasShopRunnerToken()
            ? 'Free '
            : `+${formatCurrency(best_delivery_fee)} `
        }
      </span>
      <span itemProp="description">delivery</span>
    </span>
  );
};
/* eslint-enable no-irregular-whitespace */

const DeliveryMinimum = ({ best_delivery_minimum, excludeDelivery }) => {
  if (best_delivery_minimum === 0 || excludeDelivery){
    return null;
  }
  return (
    <div
      className="delivery_minimum"
      itemProp="eligibleTransactionVolume"
      itemScope
      itemType="https://schema.org/PriceSpecification">
      <span itemProp="description">Order minimum</span>
      <meta content="USD" itemProp="priceCurrency" />
      <span
        content={best_delivery_minimum}
        itemProp="price">
        {formatCurrency(best_delivery_minimum)}
      </span>
    </div>
  );
};

const OrderMinimum = ({ cart_items, excludeDelivery, shipping, supplier }) => {
  if (excludeDelivery){
    return null;
  }

  const can_pickup = typeof _.find(supplier.deliveryMethods, { type: 'pickup' }) !== 'undefined';
  const items = cart_item_helpers.groupItemsBySupplier(cart_items);
  const delivery = shipping === 'vineyard_select' ? 'shipped' : shipping;
  const delivery_opt = _.find(supplier.deliveryMethods, { type: delivery });
  const pickup = can_pickup ? (<span>In-store pickup available.</span>) : null;

  let free_minimum = (delivery_opt && delivery_opt.free_delivery_threshold) || 10000;
  let order_minimum = delivery_opt && delivery_opt.delivery_minimum;
  let qty_products = 0;
  let msg;
  let to_add;

  if (Array.isArray(items[supplier.id])){
    const subtotal = cart_item_helpers.itemsSubtotal(items[supplier.id]);

    order_minimum = Math.max(0, order_minimum - subtotal);
    free_minimum = Math.max(0, free_minimum - subtotal);
    qty_products = _.reduce(items[supplier.id], (sum, { quantity }) => sum + quantity, 0);
  }

  switch (true){
    case qty_products === 0:
      to_add = null;
      break;
    case free_minimum === 0:
      to_add = (<span>Your order qualifies for <span className="qty">FREE delivery</span>.</span>);
      break;
    case order_minimum === 0:
      to_add = (<span>Your order meets the minimum required for delivery.</span>);
      break;
    default:
      to_add = (<span>Add <span className="addl">{formatCurrency(order_minimum)}</span> for delivery. </span>);
      break;
  }

  switch (qty_products){
    case 0:
      msg = (<span>There are no products</span>);
      break;
    case 1:
      msg = (<span>You already have <span className="qty">1 product</span></span>);
      break;
    default:
      msg = (<span>You already have <span className="qty">{qty_products} products</span></span>);
      break;
  }

  return (
    <div className="order_minimum">
      <p className="avenir_font">{to_add} {pickup}</p>
      <p className="avenir_font">
        {msg} from this store in your cart.
      </p>
    </div>
  );
};

class OrderQuantity extends React.PureComponent /* :: <OrderQuantityProps> */ {
  handleChange = (e) => {
    this.props.handleChange(parseInt(e.target.value));
  }

  render(){
    const { available, current_variant: { in_stock } } = this.props;
    const MAX_QUANTITY_DEFAULT = Math.min(24, in_stock);
    const max_quantity = Math.min(available, MAX_QUANTITY_DEFAULT) + 1;
    const quantity_range = _.range(1, max_quantity);

    return (
      <div className="order_quantity">
        <select
          id="product-quantity"
          onChange={this.handleChange}
          value={this.props.value}>
          {quantity_range.map((index) => (
            <option key={index} value={index}>
              {index}
            </option>
          ))}
        </select>
      </div>
    );
  }
}
