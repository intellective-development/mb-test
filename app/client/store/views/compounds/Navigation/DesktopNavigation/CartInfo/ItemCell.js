// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import bindClassNames from 'shared/utils/bind_classnames';
import I18n from 'store/localization';
import formatCurrency from 'shared/utils/format_currency';
import { dispatchAction } from 'shared/dispatcher';

import { cart_item_helpers, cart_item_actions } from 'store/business/cart_item';
import { product_grouping_helpers } from 'store/business/product_grouping';

import { MBLink, MBText } from '../../../../elements';
import styles from './CartDropdown.scss';

const cn = bindClassNames(styles);

type ItemCellProps = {item: Object, removeCartItem: typeof cart_item_actions.removeCartItem, show_remove_button?: boolean};
const ItemCell = ({item, removeCartItem, show_remove_button = true}: ItemCellProps) => {
  if (!item) return null;

  return (
    <li className={styles.cmCartDropdown_ItemRow_Animation}>
      <div className={styles.cmCartDropdown_ItemRow}>
        <MBLink.View
          href={product_grouping_helpers.fullPermalink(item.product_grouping, item.variant)}
          className={styles.cmCartDropdown_Item_NameImageWrapper}>
          <div className={styles.cmCartDropdown_Item_SecondaryContent}>
            <img
              className={styles.cmCartDropdown_Item_Image}
              src={product_grouping_helpers.getThumb(item.product_grouping, item.variant)}
              alt={`${item.product_grouping.name} - ${item.variant.volume}`} />
          </div>
          <div
            href={product_grouping_helpers.fullPermalink(item.product_grouping, item.variant)}
            className={cn('cmCartDropdown_Item_PrimaryContent', 'cmCartDropdown_Item_Details')}>
            <MBText.Span className={styles.cmCartDropdown_ItemName}>{item.product_grouping.name}</MBText.Span>
            <MBText.Span className={styles.cmCartDropdown_ItemVolume}>
              {item.variant.volume} {I18n.t('ui.nav.cart_dropdown.item_quantity', {count: item.quantity})}
            </MBText.Span>
            <MBText.Span className={styles.cmCartDropdown_ItemUnitPrice}>{formatCurrency(item.variant.price)}</MBText.Span>
          </div>
        </MBLink.View>
        <div className={cn('cmCartDropdown_Item_SecondaryContent', 'cmCartDropdown_Item_Price')}>
          <MBText.Span>{formatCurrency(cart_item_helpers.itemSubtotal(item))}</MBText.Span>
        </div>
        {show_remove_button && (
          <div className={cn('cmCartDropdown_Item_SecondaryContent')}>
            <RemoveItemLink cart_item_id={item.id} removeCartItem={removeCartItem} />
          </div>
        )}
      </div>
    </li>
  );
};

type OutOfStockCellProps = {
  id: number,
  name: string,
  price: string,
  quantity: number,
  total: string,
  volume: string
}

const OutOfStockCell = ({item}: OutOfStockCellProps) => {
  if (!item) return null;

  return (
    <li className={styles.cmCartDropdown_ItemRow_Animation}>
      <div className={styles.cmCartDropdown_ItemRow}>
        <div className={styles.cmCartDropdown_Item_SecondaryContent}>
          <img
            className={styles.cmCartDropdown_Out_Of_Stock_Image}
            src={'/assets/components/compounds/product_scroller/bottle_outline.png'}
            srcSet={'/assets/components/compounds/product_scroller/bottle_outline@2x.png 2x, ' +
              '/assets/components/compounds/product_scroller/bottle_outline@3x.png 3x'}
            alt={`${item.name} - ${item.volume}`} />
        </div>
        <div className={cn('cmCartDropdown_Item_PrimaryContent', 'cmCartDropdown_Item_Details')}>
          <MBText.Span className={styles.cmCartDropdown_ItemName}>{item.name}</MBText.Span>
          <MBText.Span className={styles.cmCartDropdown_ItemOutOfStock}>
            This product is currently out of stock
          </MBText.Span>
          <MBText.Span className={styles.cmCartDropdown_ItemVolume}>
            {item.volume} {I18n.t('ui.nav.cart_dropdown.item_quantity', {count: item.quantity})}
          </MBText.Span>
        </div>
        <div className={cn('cmCartDropdown_Item_SecondaryContent', 'cmCartDropdown_Item_Price')} />
      </div>
    </li>
  );
};

const RemoveItemLink = ({cart_item_id, removeCartItem}) => (
  <div
    role="button"
    tabIndex={0}
    className={styles.cmCartDropdown_Item_Remove}
    onClick={(e) => {
      e.stopPropagation();
      e.preventDefault();
      removeCartItem(cart_item_id);
      dispatchAction({
        actionType: 'track:cart:remove',
        variant_id: cart_item_id
      });
    }}>
    ×
  </div>
);

const ItemCellDTP = {removeCartItem: cart_item_actions.removeCartItem};
const ItemCellContainer = connect(null, ItemCellDTP)(ItemCell);
ItemCellContainer.OutOfStock = OutOfStockCell;

export default ItemCellContainer;
