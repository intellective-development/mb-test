import { makeSuccessAction } from '@minibar/store-business/src/utils/create_actions_for_request';
import * as ui_actions from '../actions';

import uiReducer, {
  // cartShareDiffReducer,
  shouldShowDeliveryInfoModal,
  mapSupplierId,
  shouldShowHelpModal,
  deliveryInfoShownForSuppliers,
  addressEntryModalDestination
} from '../reducer';

describe('uiReducer', () => {
  it('structures the state slice', () => {
    expect(Object.keys(uiReducer(undefined, {}))).toEqual([
      'cart_share_diff',
      'show_help_modal',
      'show_delivery_info_modal',
      'delivery_info_shown_for_suppliers',
      'address_entry_modal_destination',
      'map_supplier_id'
    ]);
  });
});

// describe('cartShareDiffReducer'); // TODO: write this

describe('showDeliveryInfoModal', () => {
  it('returns the initial state', () => {
    expect(shouldShowDeliveryInfoModal(undefined, {})).toEqual(false);
  });

  it('handles UI:SHOW_DELIVERY_INFO_MODAL', () => {
    const action = ui_actions.showDeliveryInfoModal();
    expect(shouldShowDeliveryInfoModal(false, action)).toEqual(true);
  });

  it('handles UI:HIDE_DELIVERY_INFO_MODAL', () => {
    const action = ui_actions.hideDeliveryInfoModal();
    expect(shouldShowDeliveryInfoModal(true, action)).toEqual(false);
  });
});

describe('shouldShowHelpModal', () => {
  it('returns the initial state', () => {
    expect(shouldShowHelpModal(undefined, {})).toEqual(false);
  });

  it('handles UI:SHOW_HELP_MODAL', () => {
    const action = ui_actions.showHelpModal();
    expect(shouldShowHelpModal(false, action)).toEqual(true);
  });

  it('handles UI:HIDE_HELP_MODAL', () => {
    const action = ui_actions.hideHelpModal();
    expect(shouldShowHelpModal(true, action)).toEqual(false);
  });
});

const fetchSuppliersSuccess = makeSuccessAction('SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS');
const refreshSuppliersSuccess = makeSuccessAction('SUPPLIER:REFRESH_SUPPLIERS');
describe('deliveryInfoShownForSuppliers', () => {
  it('returns the initial state', () => {
    expect(deliveryInfoShownForSuppliers(undefined, {})).toEqual(false);
  });

  it('handles SUPPLIER:FETCH_SUPPLIERS_BY_ADDRESS__SUCCESS', () => {
    const action = fetchSuppliersSuccess();
    expect(deliveryInfoShownForSuppliers(true, action)).toEqual(false);
  });

  it('handles SUPPLIER:REFRESH_SUPPLIERS__SUCCESS when suppliers_changed is true', () => {
    const action = refreshSuppliersSuccess({}, {suppliers_changed: true});
    expect(deliveryInfoShownForSuppliers(true, action)).toEqual(false);
  });

  it('handles SUPPLIER:REFRESH_SUPPLIERS__SUCCESS when suppliers_changed is false', () => {
    const action = refreshSuppliersSuccess({}, {suppliers_changed: false});
    expect(deliveryInfoShownForSuppliers(false, action)).toEqual(true);
  });

  it('handles UI:SHOW_DELIVERY_INFO_MODAL', () => {
    const action = ui_actions.showDeliveryInfoModal();
    expect(deliveryInfoShownForSuppliers(false, action)).toEqual(true);
  });

  it('handles UI:HIDE_DELIVERY_INFO_MODAL', () => {
    const action = ui_actions.hideDeliveryInfoModal();
    expect(deliveryInfoShownForSuppliers(false, action)).toEqual(true);
  });
});

describe('addressEntryModalDestination', () => {
  it('returns the initial state', () => {
    expect(addressEntryModalDestination(undefined, {})).toEqual(null);
  });

  it('handles UI:SHOW_DELIVERY_INFO_MODAL', () => {
    const action = ui_actions.showDeliveryInfoModal('/store/category/wine');
    expect(addressEntryModalDestination(null, action)).toEqual('/store/category/wine');
  });

  it('handles UI:HIDE_DELIVERY_INFO_MODAL', () => {
    const action = ui_actions.hideDeliveryInfoModal();
    expect(addressEntryModalDestination('/store/category/wine', action)).toEqual(null);
  });
});


describe('mapSupplierId', () => {
  it('returns the initial state', () => {
    expect(mapSupplierId(undefined, {})).toEqual(null);
  });

  it('handles UI:SHOW_SUPPLIER_MAP_MODAL', () => {
    const action = ui_actions.showSupplierMapModal(1);
    expect(mapSupplierId(null, action)).toEqual(1);
  });

  it('handles UI:HIDE_SUPPLIER_MAP_MODAL', () => {
    const action = ui_actions.hideSupplierMapModal();
    expect(mapSupplierId(2, action)).toEqual(null);
  });
});
