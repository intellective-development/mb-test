// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import i18n from 'store/localization';
import { dispatchAction } from 'shared/dispatcher';
import * as Ent from '@minibar/store-business/src/utils/ent';

import { cart_item_selectors } from 'store/business/cart_item';
import { search_switch_helpers } from 'store/business/search_switch';
import type { SearchSwitch } from 'store/business/search_switch';
import { supplier_actions, supplier_helpers, supplier_selectors } from 'store/business/supplier';
import type { Supplier } from 'store/business/supplier';
import { delivery_method_helpers } from 'store/business/delivery_method';
import type { DeliveryMethod } from 'store/business/delivery_method';
import type { ProductGrouping } from 'store/business/product_grouping';

import Switcher from './Switcher';
import SupplierChangeConfirmModal from './SupplierChangeConfirmModal';
import { MBLayout } from '../../../elements';

type SearchSwitcherProps = {
  search_switch: SearchSwitch,

  // STP
  product_groupings: ProductGrouping[],
  alternative_supplier: Supplier,
  alternative_delivery_method: DeliveryMethod,
  current_supplier: Supplier,
  current_delivery_method: DeliveryMethod,
  cart_is_empty: boolean,

  // DTP
  swapCurrentSupplier: typeof supplier_actions.swapCurrentSupplier,
}
type SearchSwitcherState = {
  show_modal: boolean,
  change_supplier_destination: ?string,
}

class SearchSwitcher extends React.Component<SearchSwitcherProps, SearchSwitcherState> {
  state = { show_modal: false, change_supplier_destination: null };
  static defaultProps = { product_groupings: [], alternative_supplier: {} };

  showChangeSupplierConfirmation = (permalink?: string) => {
    this.setState({show_modal: true, change_supplier_destination: permalink});
  };

  hideChangeSupplierConfirmation = () => {
    this.setState({show_modal: false, change_supplier_destination: null});
  };

  isSwitchingToShipping = () => {
    const { current_delivery_method, alternative_supplier } = this.props;
    const swap_to_delivery_method = delivery_method_helpers.replacementDeliveryMethod(alternative_supplier.delivery_methods, current_delivery_method);

    return current_delivery_method.type !== 'shipped' && swap_to_delivery_method.type === 'shipped';
  }

  getHeaderMessage = () => {
    if (this.isSwitchingToShipping()){
      return i18n.t('ui.body.product_list.confirm_swap_shipped_header');
    }

    return i18n.t('ui.body.product_list.confirm_swap_header');
  }

  getConfirmMessage = () => {
    const { current_supplier, current_delivery_method, alternative_supplier, cart_is_empty } = this.props;
    const swap_to_delivery_method = delivery_method_helpers.replacementDeliveryMethod(alternative_supplier.delivery_methods, current_delivery_method);

    let message = i18n.t('ui.body.product_list.confirm_swap_and_change_base', {
      former_supplier_name: current_supplier.name,
      former_delivery_type: delivery_method_helpers.displayName(current_delivery_method),
      next_supplier_name: alternative_supplier.name,
      next_delivery_type: delivery_method_helpers.displayName(swap_to_delivery_method)
    });
    if (!cart_is_empty) message += ` ${i18n.t('ui.body.product_list.confirm_swap_and_change_cart_warning')}`;

    return message;
  };

  changeSupplier = () => {
    const destination = this.state.change_supplier_destination || Backbone.history.getFragment(); // default to current search
    this.hideChangeSupplierConfirmation();

    const { current_supplier, alternative_supplier, alternative_delivery_method, swapCurrentSupplier } = this.props;

    swapCurrentSupplier(
      {[current_supplier.id]: alternative_supplier.id},
      {[alternative_supplier.id]: alternative_delivery_method.id},
      this.state.change_supplier_destination ? 'plp_product_tile' : 'plp'
    );
    dispatchAction({
      actionType: 'navigate',
      destination: destination
    });
  };

  render(){
    return (
      <MBLayout.StandardGrid>
        <Switcher
          product_groupings={this.props.product_groupings}
          supplier={this.props.alternative_supplier}
          delivery_method={this.props.alternative_delivery_method}
          requestChangeSupplier={this.showChangeSupplierConfirmation} />
        <SupplierChangeConfirmModal
          show={this.state.show_modal}
          is_shipping={this.isSwitchingToShipping()}
          header={this.getHeaderMessage()}
          message={this.getConfirmMessage()}
          confirm={this.changeSupplier}
          deny={this.hideChangeSupplierConfirmation} />
      </MBLayout.StandardGrid>
    );
  }
}

export function LoadingSearchSwitcher(){
  return (
    <div className="not-found">
      <h3 className="center subhead-2">SEARCHING OTHER STORES</h3>
    </div>
  );
}

const SearchSwitcherSTP = () => {
  const findAlternativeProductGroupings = Ent.query(Ent.find('search_switch.product_grouping'), Ent.join('variants', 'search_switch.variant'));
  const findAlternativeSupplier = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));
  const findSuppliers = Ent.find('supplier');
  const findDeliveryMethod = Ent.find('delivery_method');

  return (state, {search_switch}) => {
    const product_groupings = findAlternativeProductGroupings(state, search_switch_helpers.getProductGroupingIds(search_switch));
    const alternative_supplier = findAlternativeSupplier(state, search_switch_helpers.getSupplierId(search_switch));

    if (_.isEmpty(product_groupings) || !alternative_supplier) return { product_groupings };

    const current_suppliers = findSuppliers(state, supplier_selectors.currentSupplierIds(state));
    const current_supplier = current_suppliers.find(s => supplier_helpers.sameSupplierType(s, alternative_supplier));

    const current_delivery_method = findDeliveryMethod(state, supplier_selectors.supplierSelectedDeliveryMethod(state, current_supplier.id));
    const alternative_delivery_method = delivery_method_helpers.replacementDeliveryMethod(alternative_supplier.delivery_methods, current_delivery_method);
    const cart_is_empty = cart_item_selectors.cartIsEmpty(state);

    return {
      product_groupings,
      alternative_supplier,
      alternative_delivery_method,
      current_supplier,
      current_delivery_method,
      cart_is_empty
    };
  };
};
const SearchSwitcherDTP = {
  swapCurrentSupplier: supplier_actions.swapCurrentSupplier
};
const SearchSwitcherContainer = connect(SearchSwitcherSTP, SearchSwitcherDTP)(SearchSwitcher);

export default SearchSwitcherContainer;
