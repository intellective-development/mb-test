// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { supplier_selectors, supplier_helpers } from 'store/business/supplier';
import type { Supplier } from 'store/business/supplier';

import AddressSection from './AddressSection';
import SupplierRow from './SupplierRow';
import { MBModal, MBButton } from '../../../elements';

type DeliveryInfoProps = {
  current_suppliers: Array<Supplier>,
  supplier_fetch_loading: boolean,
  deliveryInfoRouteTo: Function,
  hideModal: Function
};
const DeliveryInfo = ({current_suppliers, hideModal, supplier_fetch_loading, deliveryInfoRouteTo}: DeliveryInfoProps) => {
  return (
    <div>
      <MBModal.SectionHeader
        renderRight={() => <MBModal.Close onClick={hideModal} />} >
        Delivery Address
      </MBModal.SectionHeader>
      <AddressSection deliveryInfoRouteTo={deliveryInfoRouteTo} />
      <div className="currdel__done-container">
        <MBButton expand onClick={hideModal}>Done</MBButton>
      </div>
      <SupplierList
        suppliers={current_suppliers}
        supplier_fetch_loading={supplier_fetch_loading}
        deliveryInfoRouteTo={deliveryInfoRouteTo} />
    </div>
  );
};
const DeliveryInfoSTP = () => {
  const findSuppliers = Ent.query(Ent.find('supplier'), Ent.join('delivery_methods'));
  return (state) => {
    const current_supplier_ids = supplier_selectors.currentSupplierIds(state, { ignore_lazy_loaded: true });
    const current_suppliers = supplier_helpers.primarySuppliers(findSuppliers(state, current_supplier_ids));

    return {
      current_suppliers,
      supplier_fetch_loading: supplier_selectors.fetchLoading(state)
    };
  };
};
const DeliveryInfoContainer = connect(DeliveryInfoSTP)(DeliveryInfo);

// TODO: better splitting by type? right now we're just assuming there's only going to be 1 per type
const SupplierList = ({suppliers, supplier_fetch_loading, deliveryInfoRouteTo}) => {
  if (_.isEmpty(suppliers)) return null;
  let supplier_content;

  if (supplier_helpers.hasSplitSupplierTypes(suppliers)){
    const grouped_suppliers = _.groupBy(suppliers, 'type') || {};
    // if we have split types, we render them out as a list
    supplier_content = (
      _.values(grouped_suppliers).map(supplier_group => {
        const sortedGroup = _.sortBy(supplier_group.map(supplier => {
          return supplier ? {...supplier, open: delivery_method_helpers.isClosed(supplier.delivery_methods[0])} : {};
        }), ['open', 'name']);
        return (
          <div>
            { sortedGroup ? <MBModal.SectionHeader top={false}>{sortedGroup[0].type} Stores</MBModal.SectionHeader> : null }
            <div className="currdel__sr-row">
              { sortedGroup.map(supplier => (
                <SupplierRow
                  supplier={supplier}
                  deliveryInfoRouteTo={deliveryInfoRouteTo} />
              ))}
            </div>
          </div>
        );
      })
    );
  } else {
    // otherwise, we just render it out as a single supplier
    const supplier = suppliers[0];
    supplier_content = (
      <div>
        <MBModal.SectionHeader top={false}>Your Local Store</MBModal.SectionHeader>
        <div className="currdel__sr-row">
          <SupplierRow
            supplier={supplier}
            deliveryInfoRouteTo={deliveryInfoRouteTo} />
        </div>
      </div>
    );
  }

  return (
    <div className="currdel__sl__container">
      {supplier_content}
      <SupplierListLoader is_hidden={!supplier_fetch_loading} />
    </div>
  );
};

const SupplierListLoader = ({is_hidden}) => {
  if (is_hidden) return null;

  return <div className="currdel__sl__loading-overlay" />;
};

export default DeliveryInfoContainer;
