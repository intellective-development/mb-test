import Rx from 'rxjs';
import { createStore } from 'redux';
import supplier_factory from './supplier.factory';
import address_factory from '../../address/__tests__/address.factory';
import * as mb_cookie from '../../utils/mb_cookie';

import baseReducer from '../../base_reducer';
import supplier_epics from '../epics';

jest.mock('../../utils/mb_cookie');

const { setAddressSupplierCookie } = supplier_epics;
const SUPPLIER_COOKIE_ID = 'sid';
const ADDRESS_COOKIE_ID = 'address';


// TODO: make helpers
const createMBStore = (initial_state) => createStore(baseReducer, initial_state);
const flattenToPromise = (stream, action_count = 1) => stream.take(action_count).toArray().toPromise();

describe('setAddressSupplierCookie', () => {
  const action$ = Rx.Observable.of({type: 'foo'});
  const address = address_factory.build();
  const suppliers = [
    supplier_factory.build('with_delivery_methods', {id: 1}),
    supplier_factory.build('with_delivery_methods', {id: 2})
  ];
  const formatted_supplier_ids = suppliers.map(s => s.id).join(',');
  const initial_state = {
    ...address_factory.stateify(address),
    ...supplier_factory.stateify(suppliers)
  };

  it('sets the supplier and address cookies if suppliers in state do not equal those in the cookie', () => {
    const store = createMBStore(initial_state);
    mb_cookie.__setAll({
      [ADDRESS_COOKIE_ID]: address,
      [SUPPLIER_COOKIE_ID]: '10, 222'
    });

    expect.hasAssertions();
    return setAddressSupplierCookie(action$, store).let(flattenToPromise).then(() => {
      expect(mb_cookie.set).toHaveBeenCalledWith(ADDRESS_COOKIE_ID, address, { expires: 7, path: '/' });
      expect(mb_cookie.set).toHaveBeenCalledWith(SUPPLIER_COOKIE_ID, formatted_supplier_ids, { expires: 7, path: '/' });
    });
  });

  it('sets the supplier and address cookies if address in state does not equal value in the cookie', () => {
    const store = createMBStore(initial_state);
    mb_cookie.__setAll({
      [ADDRESS_COOKIE_ID]: {foo: 'bar'},
      [SUPPLIER_COOKIE_ID]: formatted_supplier_ids
    });

    expect.hasAssertions();
    return setAddressSupplierCookie(action$, store).let(flattenToPromise).then(() => {
      expect(mb_cookie.set).toHaveBeenCalledWith(ADDRESS_COOKIE_ID, address, { expires: 7, path: '/' });
      expect(mb_cookie.set).toHaveBeenCalledWith(SUPPLIER_COOKIE_ID, formatted_supplier_ids, { expires: 7, path: '/' });
    });
  });

  it('does not set cookies if supplier is different but is falsey', () => {
    const store = createMBStore({...initial_state, supplier: { current_ids: [] }});

    mb_cookie.__setAll({
      [ADDRESS_COOKIE_ID]: address,
      [SUPPLIER_COOKIE_ID]: '10, 222'
    });

    expect.hasAssertions();
    return setAddressSupplierCookie(action$, store).let(flattenToPromise).then(() => {
      expect(mb_cookie.set).not.toHaveBeenCalled();
    });
  });

  it('does not set cookies if address is different but is falsey', () => {
    const store = createMBStore({...initial_state, address: { current_delivery_address_id: undefined }});

    mb_cookie.__setAll({
      [ADDRESS_COOKIE_ID]: {foo: 'bar'},
      [SUPPLIER_COOKIE_ID]: formatted_supplier_ids
    });

    expect.hasAssertions();
    return setAddressSupplierCookie(action$, store).let(flattenToPromise).then(() => {
      expect(mb_cookie.set).not.toHaveBeenCalled();
    });
  });

  it('does not set cookies if both values equal those in state', () => {
    const store = createMBStore(initial_state);

    mb_cookie.__setAll({
      [ADDRESS_COOKIE_ID]: address,
      [SUPPLIER_COOKIE_ID]: formatted_supplier_ids
    });

    expect.hasAssertions();
    return setAddressSupplierCookie(action$, store).let(flattenToPromise).then(() => {
      expect(mb_cookie.set).not.toHaveBeenCalled();
    });
  });
});
