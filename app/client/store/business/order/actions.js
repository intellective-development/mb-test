// @flow

// temporary actions, intended to be replaced by the shared business logic

export const resetShipmentScheduling = (is_scheduled: boolean, supplier_id: number) => ({
  type: 'ORDER:RESET_SHIPMENT_SCHEDULING',
  payload: {is_scheduled, supplier_id}
});

export const setShipmentScheduling = (scheduled_for: string, supplier_id: number) => ({
  type: 'ORDER:SET_SHIPMENT_SCHEDULING',
  payload: {scheduled_for, supplier_id}
});
