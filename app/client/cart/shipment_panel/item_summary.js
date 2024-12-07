// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import classNames from 'classnames';
import formatCurrency from 'shared/utils/format_currency';
import { product_grouping_helpers } from 'store/business/product_grouping';
import { cart_item_helpers, cart_item_actions } from 'store/business/cart_item';
import type { CartItem } from 'store/business/cart_item';
import { MBLink } from 'store/views/elements';
import { analytics_helpers, analytics_actions } from 'store/business/analytics';
import { MobileQuantitySpinner, QuantitySelect } from './quantity_select';

type ItemSummaryProps = {item: CartItem, removeCartItem: (string) => void};
type ItemSummaryState = {is_removing: boolean};
class ItemSummary extends React.Component<ItemSummaryProps, ItemSummaryState> {
  props: ItemSummaryProps
  state: ItemSummaryState = {is_removing: false}

  componentDidMount = () => {
    const { item: { product_grouping, variant, quantity }, trackEvent } = this.props;
    trackEvent({
      action: 'product_appeared_in_cart',
      content_type: 'product',
      items: [analytics_helpers.getCartItemData(product_grouping, variant, quantity)]
    });
  }

  warnRemoval = () => this.setState({is_removing: true})
  clearWarning = () => this.setState({is_removing: false})

  render(){
    const {variant, product_grouping, quantity} = this.props.item;
    if (!variant || !product_grouping || !quantity) return null;
    const {removeCartItem} = this.props;
    const {is_removing} = this.state;

    return (
      <tr className="shipment-table__item">
        <td className="shipment-table__item__property shipment-table__item__property--image__container">
          <MBLink.View href={product_grouping_helpers.fullPermalink(product_grouping, variant)} className="item__link">
            <img
              alt={product_grouping.name}
              src={product_grouping_helpers.getThumb(product_grouping, variant)}
              className="shipment-table__item__property--image" />
          </MBLink.View>
        </td>
        <td className="shipment-table__item__property shipment-table__item__property--main">
          <MBLink.View href={product_grouping_helpers.fullPermalink(product_grouping, variant)} className="item__link">
            <p className={classNames('shipment-table__item__remove-warning', {hidden: !is_removing})}>
              Item will be removed from cart.
            </p>
            <span className="shipment-table__item__property--name">{product_grouping.name}</span><br />
            <span className="shipment-table__item__property--volume">{variant.volume}</span><br />
            <span className="shipment-table__item__property--price--mobile">{formatCurrency(variant.price)}</span>
          </MBLink.View>
          <SpecialOffer variant={variant} />
        </td>
        <ItemPrice price={variant.price} original_price={variant.original_price} />
        <td className="shipment-table__item__property shipment-table__item__property--quantity">
          <QuantitySelect quantity={quantity} cart_item_id={variant.id} in_stock={variant.in_stock} /><br />
          <RemoveLink cart_item_id={variant.id} removeCartItem={removeCartItem} />
        </td>
        <td className="shipment-table__item__property shipment-table__item__property--total-price">{formatCurrency(cart_item_helpers.itemSubtotal(this.props.item))}</td>
        <td className="shipment-table__item__property shipment-table__item__property--quantity-spinner" colSpan="3">
          <MobileQuantitySpinner
            quantity={quantity}
            cart_item_id={variant.id}
            in_stock={variant.in_stock}
            warnRemoval={this.warnRemoval}
            clearWarning={this.clearWarning} />
        </td>
      </tr>
    );
  }
}

const SpecialOffer = ({variant}) => {
  if (!variant.two_for_one || !variant.deals.length) return null;
  return (
    <div>
      <span>Special Offer</span>
      {variant.deals.map(deal => (<div key={deal.short_title}><span className="deal__description">{deal.short_title}</span></div>))}
    </div>
  );
};

const ItemPrice = ({price, original_price}) => {
  const is_discounted = price !== original_price;
  return (
    <td className="shipment-table__item__property shipment-table__item__property--price">
      <span className={is_discounted ? 'shipment-table__item__property--discounted_price' : ''}>
        {formatCurrency(price)} <strike>{is_discounted && formatCurrency(original_price)}</strike>
      </span>
    </td>
  );
};

const onRemoveLinkClick = (cart_item_id, removeCartItem, e) => {
  removeCartItem(cart_item_id);
  e.preventDefault();
};

const RemoveLink = ({cart_item_id, removeCartItem}) => (
  <a
    role="button"
    tabIndex={0}
    className="shipment-table__item__remove grey-link"
    onClick={onRemoveLinkClick.bind(null, cart_item_id, removeCartItem)}>
    Remove
  </a>
);

const ItemSummaryDTP = {
  removeCartItem: cart_item_actions.removeCartItem,
  trackEvent: analytics_actions.track
};
const ItemSummaryContainer = connect(null, ItemSummaryDTP)(ItemSummary);

export default ItemSummaryContainer;
