import PropTypes from 'prop-types';
import * as React from 'react';
import { connect } from 'react-redux';
import { address_helpers } from 'store/business/address';
import { delivery_method_constants } from 'store/business/delivery_method';
import { supplier_helpers } from 'store/business/supplier';
import { ui_actions } from 'store/business/ui';

import { MBText, MBTouchable } from 'store/views/elements';

const SupplierSummary = ({shipment, showSupplierMap}) => {
  const has_pickup = shipment.supplier.delivery_methods.some(dm => dm.type === delivery_method_constants.PICKUP);

  return (
    <tr className="shipment-table__row">
      <td colSpan="5">
        <div className="shipment-table__content-container">
          <MBText.H4 className="sp_supplier__name">
            {shipment.supplier.name}
          </MBText.H4>
          <MBTouchable
            className="sp_supplier__container"
            onClick={() => showSupplierMap(shipment.supplier.id)}
            disabled={!has_pickup}>
            <MBText.H3 className="sp_supplier__location">
              {address_helpers.formatStreetAndCity(shipment.supplier.address)}
              <SupplierDistance supplier={shipment.supplier} is_hidden={!has_pickup} />
            </MBText.H3>
          </MBTouchable>
        </div>
      </td>
    </tr>
  );
};
SupplierSummary.propTypes = {
  shipment: PropTypes.object,
  showSupplierMap: PropTypes.func
};

const SupplierDistance = ({supplier, is_hidden}) => {
  if (is_hidden) return null;

  return (
    <MBText.Span>
      ・{supplier_helpers.formatDistance(supplier)}
    </MBText.Span>
  );
};

const SupplierSummaryDTP = {showSupplierMap: ui_actions.showSupplierMapModal};
const SupplierSummaryContainer = connect(null, SupplierSummaryDTP)(SupplierSummary);

export default SupplierSummaryContainer;
