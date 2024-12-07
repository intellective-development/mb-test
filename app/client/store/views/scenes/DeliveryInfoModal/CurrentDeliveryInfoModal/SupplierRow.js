// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import i18n from 'store/localization';
import { address_helpers } from 'store/business/address';
import { delivery_method_constants, delivery_method_helpers } from 'store/business/delivery_method';
import { supplier_actions, supplier_helpers, supplier_selectors } from 'store/business/supplier';
import type { Supplier } from 'store/business/supplier';

import { MBText, MBButton, MBIcon, MBTouchable } from '../../../elements';
import DeliveryMethodIcon from '../../../compounds/DeliveryMethodIcon';

type SupplierRowProps = {supplier: Supplier, selected_delivery_method_id: number, selectDeliveryMethod: Function, deliveryInfoRouteTo: Function};
const SupplierRow = ({supplier, selected_delivery_method_id, selectDeliveryMethod, deliveryInfoRouteTo}: SupplierRowProps) => {
  const has_pickup = supplier.delivery_methods.some(dm => dm.type === delivery_method_constants.PICKUP);

  return (
    <div className="currdel__sr__container">
      <div className="currdel__sr__header">
        <div className="currdel__sr__supplier">
          <MBText.H4 className="currdel__supplier-name">{supplier.name}</MBText.H4>
          <MBTouchable
            disabled={!has_pickup}
            onClick={() => deliveryInfoRouteTo('supplier_map', {supplier_id: supplier.id})}>
            <MBText.H5 className="currdel__supplier-location">
              {address_helpers.formatStreetAndCity(supplier.address)}
              <SupplierDistance supplier={supplier} is_hidden={!has_pickup} />
            </MBText.H5>
          </MBTouchable>
        </div>
        <ChangeSupplierButton
          is_hidden={!supplier_helpers.hasAlternatives(supplier)}
          onClick={() => deliveryInfoRouteTo('supplier_switching', {supplier_id: supplier.id})} />
      </div>
      {supplier.delivery_methods.map((delivery_method) => (
        <DeliveryMethodRow
          key={delivery_method.id}
          delivery_method={delivery_method}
          active={delivery_method.id === selected_delivery_method_id}
          selectDeliveryMethod={() => selectDeliveryMethod(supplier.id, delivery_method.id)} />
      ))}
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

const ChangeSupplierButton = ({is_hidden, onClick}) => {
  if (is_hidden) return null;

  // this component renders both text and an icon, and we leave it up to the styles to display the correct one for a given screen size
  return (
    <MBButton
      type="hollow"
      size="small"
      className="currdel__sr__change-button"
      onClick={onClick}>
      <MBText.Span className="currdel__sr__change-button__text">Change</MBText.Span>
      <MBIcon name="mobile.pencil" className="currdel__sr__change-button__icon" />
    </MBButton>
  );
};

const DeliveryMethodRow = ({delivery_method}) => {
  let closed_el;
  if (delivery_method_helpers.isClosed(delivery_method)){
    closed_el = (
      <MBText.Span>
        <MBText.Span className="currdel__dm-delivery-expectation--closed">
          {i18n.t('ui.body.delivery_info.delivery_method_closed')}
        </MBText.Span>
        {' - '}
      </MBText.Span>
    );
  }

  return (
    <div className="currdel__dm-container" >
      <DeliveryMethodIcon
        delivery_method_type={delivery_method.type}
        width={30}
        height={30}
        className="currdel__dm-icon" />
      <div>
        <MBText.H4 className="currdel__dm-name">
          {delivery_method_helpers.displayName(delivery_method)}
        </MBText.H4>
        <MBText.H5 className="currdel__dm-delivery-expectation">
          {closed_el}
          {delivery_method_helpers.formatNextDelivery(delivery_method)}
        </MBText.H5>
      </div>
    </div>
  );
};

const SupplierRowSTP = (state, {supplier}) => ({
  selected_delivery_method_id: supplier_selectors.selectedDeliveryMethods(state)[supplier.id]
});
const SupplierRowDTP = {selectDeliveryMethod: supplier_actions.selectDeliveryMethod};
const SupplierRowContainer = connect(SupplierRowSTP, SupplierRowDTP)(SupplierRow);

export default SupplierRowContainer;
