// @flow

import * as React from 'react';
import { product_grouping_helpers } from 'store/business/product_grouping';
import formatCurrency from 'shared/utils/format_currency';
import { cart_item_helpers } from 'store/business/cart_item';

import { MBText, MBTouchable } from '../../../elements';

const LIST_INITIAL_LENGTH = 3;

type ItemListProps = { items: Array<Object> };
type ItemListState = { show_all: boolean };
class ItemList extends React.PureComponent<ItemListProps, ItemListState> {
  state = {show_all: false}

  showAllItems = () => {
    this.setState({show_all: true});
  }

  render(){
    const { items } = this.props;
    const { show_all } = this.state;
    const has_hidden_items = items.length > LIST_INITIAL_LENGTH && !show_all;

    let display_items = items;
    if (!show_all) display_items = items.slice(0, LIST_INITIAL_LENGTH);

    return (
      <div className="csl__item-list-container">
        {display_items.map(item => (
          <ItemListElement item={item} key={item.variant.id} />
        ))}
        <ShowAll is_hidden={!has_hidden_items} showAllItems={this.showAllItems} />
      </div>
    );
  }
}

const ItemListElement = ({item}) => {
  const {variant, product_grouping, quantity} = item;
  let volume_el = '';
  if (variant.volume){
    volume_el = <span>&nbsp;&ndash;&nbsp;{variant.volume}</span>;
  }

  return (
    <div className="csl__item-container">
      <img
        alt={product_grouping.name}
        src={product_grouping_helpers.getThumb(product_grouping, variant)}
        className="csl__item-image" />
      <div className="csl__item-detail__container">
        <MBText.Span className="csl__item-detail__text">
          {product_grouping.name}
        </MBText.Span>
        <MBText.Span className="csl__item-detail__text">
          Qty: {quantity}&nbsp;&ndash;&nbsp;{formatCurrency(cart_item_helpers.itemSubtotal(item))}{volume_el}
        </MBText.Span>
      </div>
    </div>
  );
};

const ShowAll = ({is_hidden, showAllItems}) => {
  if (is_hidden) return null;

  return (
    <MBTouchable onClick={showAllItems} className="secondary-action show-all">Show all items</MBTouchable>
  );
};

export default ItemList;
