// @flow
import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import I18n from 'store/localization';
import { address_selectors } from 'store/business/address';
import { supplier_helpers, supplier_selectors } from 'store/business/supplier';
import type { Address } from 'store/business/address';
import type { DeliveryMethod, DeliveryMethodType } from 'store/business/delivery_method';

import { MBLoader, MBText } from '../../../elements';
import { MultiDeliveryMethodIcon } from '../../DeliveryMethodIcon';
import styles from './DeliveryInfo.scss';

type DeliveryInfoProps = {|
  current_address: Address,
  selected_delivery_methods: DeliveryMethod[],
  address_fetching: boolean
|};

const DeliveryInfo = ({current_address, selected_delivery_methods, address_fetching}: DeliveryInfoProps) => {
  let delivery_method_types = selected_delivery_methods.map(dm => dm.type);
  if (_.isEmpty(delivery_method_types)){
    delivery_method_types = ['on_demand'];
  }

  let content;
  if (current_address){
    content = <MBText.Span className={styles.cmNavDeliveryInfo_Address}>{formatAddress(current_address)}</MBText.Span>;
  } else if (address_fetching){
    content = <MBLoader />;
  } else {
    content = <MBText.Span className={styles.cmNavDeliveryInfo_AddAddress}>Add delivery address</MBText.Span>;
  }

  return (
    <div className={styles.cmNavDeliveryInfo_Container}>
      <MultiDeliveryMethodIcon
        width={24}
        height={24}
        delivery_method_types={delivery_method_types} />
      <div>
        <MBText.Span className={styles.cmNavDeliveryInfo_TextTitle}>
          {deliveryMessage(delivery_method_types)}
        </MBText.Span><br />
        {content}
      </div>
    </div>
  );
};


const DeliveryInfoSTP = () => {
  const findAddress = Ent.find('address');
  const findSuppliers = Ent.find('supplier');
  const findDeliveryMethods = Ent.find('delivery_method');

  return (state) => {
    const current_suppliers = findSuppliers(state, supplier_selectors.currentSupplierIds(state));
    const display_suppliers = supplier_helpers.displaySuppliers(current_suppliers);

    const selected_delivery_method_ids = display_suppliers.map(s => supplier_selectors.supplierSelectedDeliveryMethod(state, s.id));
    const selected_delivery_methods = findDeliveryMethods(state, selected_delivery_method_ids);

    return {
      current_address: findAddress(state, address_selectors.currentDeliveryAddressId(state)),
      address_fetching: address_selectors.isFetching(state),
      selected_delivery_methods
    };
  };
};
const DeliveryInfoContainer = connect(DeliveryInfoSTP)(DeliveryInfo);

export default DeliveryInfoContainer;

// utils

const formatAddress = (address: Address) => {
  if (!address.address2) return address.address1;
  return `${address.address1}, ${address.address2}`;
};

const deliveryMessage = (delivery_method_types: DeliveryMethodType[]) => {
  const uniq_types = _.uniq(delivery_method_types);
  const icon_name = _.sortBy(uniq_types).join('__');

  return I18n.t(`ui.nav.delivery_info.${icon_name}`);
};

export const __private__ = {
  deliveryMessage
};
