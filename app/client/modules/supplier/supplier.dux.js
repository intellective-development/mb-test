import { createSelector } from 'reselect';

import { supplier_actions } from 'store/business/supplier';

import { selectDeliveryMethodById } from '../deliveryMethod/deliveryMethod.dux';

const localState = ({ supplier }) => supplier;

export const selectCurrentMethodBySupplierId = state => id => localState(state).selected_delivery_methods[id];
export const selectCurrentSuppliers = state => localState(state).current_ids;
export const selectSelectedDeliveryMethods = state => localState(state).selected_delivery_methods;
export const selectSelectedDeliveryMethodBySupplierId = state => selectSelectedDeliveryMethods(state);
export const selectSupplierById = state => id => localState(state).by_id[id];
export const selectSupplier = createSelector(
  selectSupplierById,
  selectDeliveryMethodById,
  (supplierById, deliveryMethodById) => id => {
    const supplier = supplierById(id);
    return ({
      ...supplier,
      delivery_method: deliveryMethodById[supplier.delivery_method_id]
    });
  }
);

export const setDeliveryMethod = supplier_actions.selectDeliveryMethod;
