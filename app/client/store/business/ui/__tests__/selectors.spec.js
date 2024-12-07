import {
  // getCartShareDiff,
  isDeliveryInfoModalShowing,
  showSupplierMap,
  mapSupplierId,
  isHelpModalShowing,
  hasDeliveryInfoForSuppliersBeenShown,
  addressEntryModalDestination
} from '../selectors';

describe('isDeliveryInfoModalShowing', () => {
  it('returns the delivery_info_modal in state', () => {
    const state = { show_delivery_info_modal: false };
    expect(isDeliveryInfoModalShowing(state)).toEqual(false);
  });
});

describe('isHelpModalShowing', () => {
  it('returns the show_help_modal value in state', () => {
    const state = {show_help_modal: true};
    expect(isHelpModalShowing(state)).toEqual(true);
  });
});

describe('hasDeliveryInfoForSuppliersBeenShown', () => {
  it('returns the delivery_info_shown_for_suppliers value in state', () => {
    const state = {delivery_info_shown_for_suppliers: true};
    expect(hasDeliveryInfoForSuppliersBeenShown(state)).toEqual(true);
  });
});

describe('addressEntryModalDestination', () => {
  it('returns the address_entry_modal_destination value in state', () => {
    const state = {address_entry_modal_destination: '/store/category/wine'};
    expect(addressEntryModalDestination(state)).toEqual('/store/category/wine');
  });
});

describe('showSupplierMap', () => {
  it('returns true if there is a map_supplier_id specified', () => {
    const state = {map_supplier_id: 1};
    expect(showSupplierMap(state)).toEqual(true);
  });

  it('returns false if there is no map_supplier_id specified', () => {
    const state = {map_supplier_id: null};
    expect(showSupplierMap(state)).toEqual(false);
  });
});

describe('mapSupplierId', () => {
  it('returns the map_supplier_id if specified', () => {
    const state = {map_supplier_id: 1};
    expect(mapSupplierId(state)).toEqual(1);
  });

  it('returns null if the map_supplier_id is not specified', () => {
    const state = {map_supplier_id: null};
    expect(mapSupplierId(state)).toEqual(null);
  });
});
