// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import I18n from 'store/localization';

import bindClassNames from 'shared/utils/bind_classnames';
import { CSSTransition, TransitionGroup } from 'react-transition-group';
import formatCurrency from 'shared/utils/format_currency';
import { cart_item_helpers } from 'store/business/cart_item';
import { supplier_selectors } from 'store/business/supplier';

import ItemCell from './ItemCell';
import { MBLink, MBText } from '../../../../elements';
import styles from './CartDropdown.scss';

const cn = bindClassNames(styles);
const MAX_ITEMS_SHOWN = 4;

const OrderMinimum = ({ excludeDelivery, items, supplier }) => {
  if (excludeDelivery){
    return null;
  }

  const minimum = formatCurrency(supplier.best_delivery_minimum);
  const subtotal = cart_item_helpers.itemsSubtotal(items);
  const min_met = subtotal >= supplier.best_delivery_minimum;

  return min_met
    ? null
    : (<span className="cmCartDropdown_MinWarning">{minimum} minimum</span>);
};

const SupplierName = ({ name } /* : Supplier */) => (
  <div className="cmCartDropdown_SupplierName">
    {name}
  </div>
);

const BySupplier = ({ items, supplier }) => {
  const sorted_items = _.sortBy(items, item => item.updated_at * -1);
  const visible_items = sorted_items.slice(0, MAX_ITEMS_SHOWN);
  const overflow_items = sorted_items.slice(MAX_ITEMS_SHOWN);
  const excludeDelivery = _.map(
    items,
    ({ product_grouping }) =>
      _.uniq(product_grouping.tags).includes('bartender')
  ).every(t => t === true);

  return (
    <React.Fragment>
      <div className="cmCartDropdown_Supplier">
        <SupplierName {...supplier} />
        <div>
          <OrderMinimum
            excludeDelivery={excludeDelivery}
            items={items}
            supplier={supplier} />
        </div>
      </div>
      {visible_items.map(item => <ItemCell item={item} key={item.variant.id} />)}
      <ItemOverflowMessage items={overflow_items} />
    </React.Fragment>
  );
};

type ItemListProps = {|
  items: Object[]
|}
type ItemListState = {|
  do_animation: boolean
|};

class ItemList extends React.Component<ItemListProps, ItemListState> {
  state = { do_animation: false }
  static defaultProps = { items: [] }

  componentWillReceiveProps(nextProps){
    // Only want to do animation when the number of visible products changes.
    // So that means, only when we're below the max # of visible products or when we've just increased to the max.
    // If we've decreased to the max, we already had max # showing, so dont want animation.
    const below_max = nextProps.items.length < MAX_ITEMS_SHOWN;
    const increasing_to_max = nextProps.items.length === MAX_ITEMS_SHOWN && nextProps.items.length > this.props.items.length;

    this.setState({do_animation: below_max || increasing_to_max});
  }

  render(){
    const { items, suppliers } = this.props;
    const by_supplier = _.groupBy(items, 'supplier_id');

    return (
      <ul className={styles.cmCartDropdown_ItemList}>
        <TransitionGroup>
          <CSSTransition
            classNames="cmCartDropdown_ItemRow_Animation-"
            timeout={{ enter: 200, exit: 200 }}
            appear={this.state.do_animation}
            exit={this.state.do_animation}
            component="div">
            <React.Fragment>
              {_.toPairs(by_supplier).map(([key, val]) => {
                const supplier = _.find(suppliers, { id: parseInt(key) });

                return typeof supplier === 'undefined'
                  ? null
                  : (<BySupplier items={val} key={supplier.id} supplier={supplier} />);
              })}
            </React.Fragment>
          </CSSTransition>
        </TransitionGroup>
      </ul>
    );
  }
}

const ItemOverflowMessage = ({items}) => {
  if (items.length <= 0) return null;

  const overflow_count_label = I18n.t('ui.nav.cart_dropdown.item_count', {count: cart_item_helpers.itemListQuantity(items) || 0});

  return (
    <li>
      <MBLink.View href="/store/cart" className={cn('cmCartDropdown_ItemRow', 'cmCartDropdown_ItemRow_Overflow')}>
        <div className={styles.cmCartDropdown_Item_SecondaryContent}>
          <div className={styles.cmCartDropdown_Item_ImagePlaceholder}>+</div>
        </div>
        <div className={styles.cmCartDropdown_Item_PrimaryContent}>
          <MBText.Span className={styles.cmCartDropdown_Item_OverflowCount}>{overflow_count_label}</MBText.Span>
        </div>
        <div className={cn('cmCartDropdown_Item_SecondaryContent', 'cmCartDropdown_Item_Price')}>
          <MBText.Span>{formatCurrency(cart_item_helpers.itemsSubtotal(items))}</MBText.Span>
        </div>
        <div className={styles.cmCartDropdown_Item_SecondaryContent}>
          <div className={styles.cmCartDropdown_Item_RemovePlaceholder} />
        </div>
      </MBLink.View>
    </li>
  );
};

const getSupplier = state => supplier_id => {
  const supplier = state.supplier.by_id[supplier_id] || {};
  supplier.deliveryMethods = _.compact(_.map(supplier.delivery_methods, id => state.delivery_method.by_id[id]));
  return supplier;
};
const getSuppliersById = state => ids => _.map(ids, getSupplier(state));

const ItemListSTP = state => ({
  suppliers: getSuppliersById(state)(supplier_selectors.currentSupplierIds(state))
});

export default connect(ItemListSTP)(ItemList);
