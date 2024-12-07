// @flow

import I18n from 'store/localization';
import { delivery_method_constants, delivery_method_helpers } from 'store/business/delivery_method';
import type { DeliveryMethod } from 'store/business/delivery_method';
import type { Supplier } from 'store/business/supplier';
import { cart_item_helpers } from 'store/business/cart_item';
import formatCurrency from 'shared/utils/format_currency';

export type Shipment = {
  items: Array<Object>,
  supplier: Supplier,
  delivery_method: DeliveryMethod
}

export function shipmentItemCount(shipment: Shipment){
  return cart_item_helpers.itemListQuantity(shipment.items);
}

export function shipmentSubtotal(shipment: Shipment){
  return cart_item_helpers.itemsSubtotal(shipment.items);
}

export function shipmentBelowDeliveryMinimum(shipment: Shipment){
  return delivery_method_helpers.belowMinimum(shipment.delivery_method, shipmentSubtotal(shipment));
}

export function shipmentMinimumDifference(shipment: Shipment){
  return shipment.delivery_method.delivery_minimum - parseFloat(shipmentSubtotal(shipment));
}

// TODO: this is nearly identical to a helper in cider, when we're using the same shipment abstraction we should merge them
export const meetMinimumMessage = (shipment: Shipment) => { // TODO: copy pasta some tests
  const curr_delivery_method = shipment.delivery_method;
  const subtotal = shipmentSubtotal(shipment);

  // Take the first delivery method that isn't the current one.
  // We only take one as we assume the user will never see more than two dm's per supplier
  const alt_delivery_method = shipment.supplier.delivery_methods.find(dm => dm.id !== curr_delivery_method.id);

  let message;
  if (!delivery_method_helpers.belowMinimum(curr_delivery_method, subtotal)){
    message = '';
  } else if (!alt_delivery_method){
    message = I18n.t('client_entities.order.under_minimum.no_alt', {
      curr_minimum_difference: formatCurrency(curr_delivery_method.delivery_minimum - subtotal),
      curr_delivery_type: delivery_method_helpers.displayName(curr_delivery_method).toLowerCase()
    });
  } else if (!delivery_method_helpers.belowMinimum(alt_delivery_method, subtotal)){
    message = I18n.t('client_entities.order.under_minimum.above_alt', {
      curr_minimum_difference: formatCurrency(curr_delivery_method.delivery_minimum - subtotal),
      curr_delivery_type: delivery_method_helpers.displayName(curr_delivery_method).toLowerCase(),
      alt_delivery_type: delivery_method_helpers.displayName(alt_delivery_method).toLowerCase()
    });
  } else {
    message = I18n.t('client_entities.order.under_minimum.under_alt', {
      curr_minimum_difference: formatCurrency(curr_delivery_method.delivery_minimum - subtotal),
      curr_delivery_type: delivery_method_helpers.displayName(curr_delivery_method).toLowerCase(),
      alt_minimum_difference: formatCurrency(alt_delivery_method.delivery_minimum - subtotal),
      alt_delivery_type: delivery_method_helpers.displayName(alt_delivery_method).toLowerCase()
    });
  }

  // FIXME: this is a workaround for a bug in i18n.js where it mangles '$' chars if more than one is present in the string
  return message.replace(/_#\$#_/g, '$');
};

export const validateShipment = (shipment: Shipment) => {
  if (shipment.scheduled && !shipment.scheduled_for){
    return { name: 'SchedulingIncomplete' };
  } else if (delivery_method_helpers.mustBeScheduled(shipment.delivery_method) && !shipment.scheduled_for){
    return { name: 'SchedulingMissing' };
  } else {
    return null;
  }
};

const { ON_DEMAND, SHIPPED, PICKUP } = delivery_method_constants;
export const hasPickupShipments = (shipments: Array<Shipment>) => {
  return shipments.some(shipment => shipment.delivery_method.type === PICKUP);
};

export const hasShippedShipments = (shipments: Array<Shipment>) => {
  return shipments.some(shipment => shipment.delivery_method.type === SHIPPED);
};

export const hasOnDemandShipments = (shipments: Array<Shipment>) => {
  return shipments.some(shipment => shipment.delivery_method.type === ON_DEMAND);
};

export const hasAddressShipments = (shipments: Array<Shipment>) => {
  return hasShippedShipments(shipments) || hasOnDemandShipments(shipments);
};
