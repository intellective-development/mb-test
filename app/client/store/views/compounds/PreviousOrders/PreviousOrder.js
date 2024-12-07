// @flow

import * as React from 'react';
import _ from 'lodash';
import { formatDateLong } from '@minibar/store-business/src/utils/format_date';
import I18n from 'store/localization';
import type { DeliveryMethodType } from 'store/business/delivery_method';
import type { Address } from 'store/business/address';
import { address_helpers } from 'store/business/address';
import type { Variant } from 'store/business/variant';
import type { CartShare } from 'store/business/cart_share';
import type { ProductGrouping } from 'store/business/product_grouping';
import formatCurrency from 'shared/utils/format_currency';
import bindClassNames from 'shared/utils/bind_classnames';
import { MBButton, MBCard, MBLoader, MBLink, MBText } from '../../elements';
import WithAnalyticsTracking from '../WithAnalyticsTracking';
import ItemCell from '../Navigation/DesktopNavigation/CartInfo/ItemCell';
import WithCartShare from './WithCartShare';
import styles from './PreviousOrder.scss';


const cn = bindClassNames(styles);

export type PreviousOrderProps = {
  current_address: Address,
  cart_share_id: number,
  order_number: number,
  date: string,
  shipping_type: DeliveryMethodType,
  shipping_address: Address,
  subtotal: number,
  items: Array<{
    quantity: number,
    variant: Variant,
    product_grouping: ProductGrouping
  }>
}

type PreviousOrderState = {
  show_all_items: boolean,
}

const INITIAL_ITEM_DISPLAY_COUNT = 2;

class PreviousOrder extends React.Component<PreviousOrderProps, PreviousOrderState> {
  state = { show_all_items: false }

  showAllItems = () => this.setState({ show_all_items: true })

  renderLoading = () => (
    <MBCard className={cn('cmPreviousOrder__Loading')}>
      <MBCard.Title>
        <MBText.Span>&nbsp;</MBText.Span>
      </MBCard.Title>
      <MBCard.Section className={cn('cmPreviousOrder__LoaderContainer')}>
        <MBLoader />
      </MBCard.Section>
    </MBCard>
  )

  renderOrder = (cart_share: CartShare) => {
    const { show_all_items } = this.state;

    const cart_share_id = _.get(cart_share, 'id');
    const items = _.get(cart_share, 'items');
    const order_items = _.get(cart_share, 'order.order_items');
    const completed_at = _.get(cart_share, 'order.completed_at');
    const shipping_address = _.get(cart_share, 'order.shipping_address');
    const order_number = _.get(cart_share, 'order.number');
    const shipping_type = _.get(cart_share, 'order.shipping_method_types[0]');

    const out_of_stock_items = _.differenceBy(order_items, items.map(item => item.variant), item => item.id);
    const merged_items = [
      ...items.map(item => ({...item, type: 'in_stock' })),
      ...out_of_stock_items.map(item => ({...item, type: 'out_of_stock' }))
    ];
    const subtotal = items.reduce((acc, item) => acc + (item.variant.price * item.quantity), 0);
    const date = formatDateLong(completed_at);
    const displayed_items = show_all_items ? merged_items : merged_items.slice(0, INITIAL_ITEM_DISPLAY_COUNT);
    const hidden_item_count = merged_items.length - displayed_items.length;

    return (
      <MBCard className={cn('cmPreviousOrder')}>
        <MBCard.Title>
          <MBText.Span>{date}</MBText.Span>
        </MBCard.Title>
        <MBCard.Section>
          <MBText.Span className={cn('cmPreviousOrder__OrderNumber')}>Order #{order_number}</MBText.Span>
          <MBText.Span className={cn('cmPreviousOrder__DeliveryInfo')}>
            {I18n.t(`ui.reorder.past_delivery_info.${shipping_type}`, { address: address_helpers.formatStreet(shipping_address) })}
          </MBText.Span>
          <br />
          {displayed_items.some(item => item.type === 'in_stock') ? (
            <WithAnalyticsTracking render={({ track }) => (
              <MBLink.View
                href={`/store/cart_share/${cart_share_id}`}
                beforeNavigate={() => track({ category: 'reorder', action: 'reorder from card', label: 'previous order page' })}>
                <MBButton type={'action'} expand>
                  <MBText.Span>Re-order</MBText.Span>
                </MBButton>
              </MBLink.View>
            )} />
          ) : (
            <MBButton type={'action'} expand disabled>
              <MBText.Span>Out of stock</MBText.Span>
            </MBButton>
          )}
        </MBCard.Section>
        <div className={cn('cmPreviousOrder__Items')}>
          {displayed_items.map(item => (item.type === 'in_stock'
            ? <ItemCell key={item.variant.id} item={item} show_remove_button={false} />
            : <ItemCell.OutOfStock key={item.id} item={item} />
          ))}
        </div>
        {/* For design reasons, this element can be both hidden (taking up height) and entirely removed from the DOM */}
        {!show_all_items && (
          <MBCard.Section className={cn({ cmPreviousOrder__HiddenCardSection: hidden_item_count === 0 })}>
            <MBText.A onClick={this.showAllItems} className={cn('cmPreviousOrder__ShowMoreText')}>
              {I18n.t('ui.reorder.show_more', { count: hidden_item_count })}
            </MBText.A>
          </MBCard.Section>
        )}
        <MBCard.Spacer />
        <MBCard.Section className={cn('cmPreviousOrder__PriceRow')}>
          <MBText.Span>{I18n.t('ui.reorder.subtotal', { count: items.length })}</MBText.Span>
          <MBText.Span>{formatCurrency(subtotal)}</MBText.Span>
        </MBCard.Section>
      </MBCard>
    );
  }

  render(){
    const { cart_share_id } = this.props;

    return (
      <WithCartShare
        cart_share_id={cart_share_id}
        render={({ cart_share, is_loading }) => ((is_loading || !cart_share) ? this.renderLoading() : this.renderOrder(cart_share))} />
    );
  }
}

export default PreviousOrder;
