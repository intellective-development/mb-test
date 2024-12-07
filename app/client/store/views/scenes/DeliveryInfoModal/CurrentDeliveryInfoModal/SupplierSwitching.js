// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import cn from 'classnames';
import * as Ent from '@minibar/store-business/src/utils/ent';
import i18n from 'store/localization';

import { address_helpers, address_selectors } from 'store/business/address';
import { delivery_method_helpers } from 'store/business/delivery_method';
import type { DeliveryMethod } from 'store/business/delivery_method';
import { supplier_actions, supplier_helpers, supplier_selectors } from 'store/business/supplier';
import type { Supplier } from 'store/business/supplier';
import { cart_item_selectors } from 'store/business/cart_item/index';
import { analytics_actions } from 'store/business/analytics';
import formatCurrency from 'shared/utils/format_currency';
import FullPageLoader from 'shared/components/full_page_loader';
import { dispatchAction } from 'shared/dispatcher';

import { MBIcon, MBGrid, MBModal, MBText, MBTouchable } from '../../../elements';

type SupplierSwitchingProps = {
  initial_supplier: Supplier,
  current_supplier_id: number,
  is_cart_empty: boolean,
  current_delivery_method: DeliveryMethod,
  alternative_suppliers: Array<Supplier>,
  swapCurrentSupplier: Function,
  fetchAlternatives: Function,
  routeBack: Function,
  hideModal: Function,
  trackAddressModal(location: string): void;
};

class SupplierSwitching extends React.Component<SupplierSwitchingProps> {
  componentDidMount(){
    this.props.trackAddressModal('view_change_supplier');

    if (this.props.alternatives_not_loaded){
      this.props.fetchAlternatives();
    }
  }

  switchSuppliers = (swap_to_supplier) => {
    const { current_supplier_id, current_delivery_method, swapCurrentSupplier, routeBack } = this.props;
    const swap_to_delivery_method = delivery_method_helpers.replacementDeliveryMethod(swap_to_supplier.delivery_methods, current_delivery_method);

    swapCurrentSupplier(
      {[current_supplier_id]: swap_to_supplier.id},
      {[swap_to_supplier.id]: swap_to_delivery_method.id},
      'supplier_modal'
    );
    dispatchAction({
      actionType: 'navigate',
      destination: '/'
    });

    routeBack();
  }

  renderContent(){
    if (this.props.alternatives_not_loaded) return <SupplierSwitchingLoading />; // TODO: loading state

    const { initial_supplier, current_supplier_id, alternative_suppliers } = this.props;
    const all_suppliers = [initial_supplier, ...alternative_suppliers];

    return (
      <MBGrid cols={1} medium_cols={2} large_cols={3} className="ssw__grid" >
        {all_suppliers.map(supplier => (
          <SupplierTile
            onClick={() => this.switchSuppliers(supplier)}
            supplier={supplier}
            is_current={supplier.id === current_supplier_id}
            key={supplier.id} />
        ))}
      </MBGrid>
    );
  }

  render(){
    const { routeBack, hideModal, is_cart_empty } = this.props;

    return (
      <div>
        <MBModal.SectionHeader
          renderLeft={() => <MBModal.Back onClick={routeBack} />}
          renderRight={() => <MBModal.Close onClick={hideModal} />} >
          Change Store
        </MBModal.SectionHeader>
        <CartWarning is_hidden={is_cart_empty} />
        {this.renderContent()}
      </div>
    );
  }
}

const CartWarning = ({is_hidden}) => {
  if (is_hidden) return null;

  return (
    <MBText.H4 className="ssw__cart-warning">
      {i18n.t('ui.body.delivery_info.switch_store_cart_warning')}
    </MBText.H4>
  );
};

const SupplierTile = ({supplier, is_current, onClick}) => {
  const container_classes = cn('ssw__supplier__container', {'ssw__supplier__container--current': is_current});
  const has_pickup = supplier.delivery_methods.some(dm => dm.type === 'pickup');

  return (
    <li className="ssw__grid__item">
      <MBTouchable className={container_classes} onClick={onClick}>
        <div className="ssw__supplier__header">
          <SupplierCurrentBadge is_hidden={!is_current} />
          <MBText.H4 className="ssw__supplier-name">{supplier.name}</MBText.H4>
          <MBText.H5 className="ssw__supplier-location">
            {address_helpers.formatStreetAndCity(supplier.address)}
            <SupplierDistance supplier={supplier} is_hidden={!has_pickup} />
          </MBText.H5>
        </div>
        <div className="ssw__supplier__body">
          <SupplierCategories supplier={supplier} />
          <SupplierDeliveryMethods delivery_methods={supplier.delivery_methods} />
        </div>
      </MBTouchable>
    </li>
  );
};

const SupplierCurrentBadge = ({is_hidden}) => {
  if (is_hidden) return null;
  return (
    <div className="ssw__supplier__current-badge">
      <MBIcon name="check" />
    </div>
  );
};

const SupplierDistance = ({supplier, is_hidden}) => {
  if (is_hidden) return null;

  return (
    <MBText.Span>
      ・{supplier_helpers.formatDistance(supplier)}
    </MBText.Span>
  );
};

const SupplierCategories = ({supplier}) => {
  const categories = supplier_helpers.whitelistedCategories(supplier);
  if (_.isEmpty(categories)) return null;

  return (
    <MBGrid className="ssw__category__list" cols={2}>
      {_.map(categories, (category_count: number, category_name: string) => (
        <SupplierCategory category_name={category_name} category_count={category_count} key={category_name} />
      ))}
    </MBGrid>
  );
};

const SupplierCategory = ({category_name, category_count}) => (
  <li>
    <MBText.Span className="ssw__category__bullet" />&nbsp;
    <MBText.Span className="ssw__category__name">
      {_.startCase(category_name)} ({category_count})
    </MBText.Span>
  </li>
);

const SupplierDeliveryMethods = ({delivery_methods}) => (
  <ul className="ssw__dm__list">
    {delivery_methods.map(delivery_method =>
      <DeliveryMethodRow delivery_method={delivery_method} key={delivery_method.id} />
    )}
  </ul>
);

const DeliveryMethodRow = ({delivery_method}) => {
  let delivery_content;
  if (delivery_method_helpers.isClosed(delivery_method)){
    delivery_content = (
      <MBText.Span className="ssw__dm__details ssw__dm__details--closed">
        {i18n.t('ui.body.delivery_info.delivery_method_closed')}
      </MBText.Span>
    );
  } else {
    let formatted_delivery_fee = formatCurrency(delivery_method.delivery_fee, {truncate: true, use_free: true});
    if (delivery_method.delivery_fee > 0){
      formatted_delivery_fee = i18n.t('ui.body.delivery_info.delivery_fee', {delivery_fee: formatted_delivery_fee});
    }

    delivery_content = (
      <MBText.Span className="ssw__dm__details">
        {formatted_delivery_fee}・
        {formatMinimumDescription(delivery_method.delivery_minimum)}
      </MBText.Span>
    );
  }

  return (
    <li className="ssw__dm__item">
      <MBText.Span className="ssw__dm__name">{delivery_method_helpers.displayName(delivery_method)}・</MBText.Span>
      {delivery_content}
    </li>
  );
};

const SupplierSwitchingLoading = () => {
  return <FullPageLoader hidden={false} />;
};

const SupplierSwitchingSTP = () => {
  // TODO: the address join syntax is a workaround for an Ent bug
  const findSuppliers = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));
  const findDeliveryMethod = Ent.find('delivery_method');
  const findAddress = Ent.find('address');

  return (state, {supplier_id}) => {
    const initial_supplier = findSuppliers(state, supplier_id);
    const alternative_suppliers = _.compact(findSuppliers(state, initial_supplier.alternatives));

    const initial_and_alternative_suppliers = [initial_supplier, ...alternative_suppliers];
    const unfetched_alternative_ids = supplier_helpers.unfetchedAlternativeIds(initial_and_alternative_suppliers);

    const current_supplier = initial_and_alternative_suppliers.find(supplier => supplier.id === supplier_id);
    const current_supplier_id = current_supplier && current_supplier.id;
    const current_delivery_method = findDeliveryMethod(state, supplier_selectors.supplierSelectedDeliveryMethod(state, current_supplier_id));

    return {
      initial_supplier,
      alternative_suppliers,
      current_supplier_id,
      current_delivery_method,
      alternatives_not_loaded: _.some(unfetched_alternative_ids),
      is_cart_empty: cart_item_selectors.cartIsEmpty(state),

      // MP props
      unfetched_alternative_ids,
      delivery_address: findAddress(state, address_selectors.currentDeliveryAddressId(state))
    };
  };
};
const SupplierSwitchingDTP = {
  fetchAlternatives: supplier_actions.fetchSuppliersFromIds,
  swapCurrentSupplier: supplier_actions.swapCurrentSupplier,
  trackAddressModal: (location: string) => analytics_actions.track({ category: 'address_modal', action: location })
};
const SupplierSwitchingMP = (state_props, dispatch_props, own_props) => ({
  ...own_props,
  ...state_props,
  ...dispatch_props,
  fetchAlternatives: () => (
    dispatch_props.fetchAlternatives(state_props.unfetched_alternative_ids, state_props.delivery_address)
  )
});
const SupplierSwitchingContainer = connect(SupplierSwitchingSTP, SupplierSwitchingDTP, SupplierSwitchingMP)(SupplierSwitching);

export default SupplierSwitchingContainer;

// helpers
const formatMinimumDescription = (delivery_minimum: number) => {
  const minimum_val = delivery_minimum > 0 ? formatCurrency(delivery_minimum, {truncate: true}) : 'No';
  return i18n.t('ui.body.delivery_info.delivery_minimum', {delivery_minimum: minimum_val});
};
