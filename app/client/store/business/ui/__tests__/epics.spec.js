import Rx from 'rxjs';
import { createStore } from 'redux';
import { makeSuccessAction } from '@minibar/store-business/src/utils/create_actions_for_request';
import address_factory from 'store/business/address/__tests__/address.factory';

import { actionStream } from 'shared/dispatcher';
import baseReducer from '../../base_reducer';
import * as ui_actions from '../actions';
import * as ui_utils from '../utils';
import ui_epics from '../epics';

jest.mock('shared/dispatcher');
jest.mock('../utils');

const { routeExternal } = ui_epics;

// TODO: make helpers
const createMBStore = (initial_state) => createStore(baseReducer, initial_state);
const flattenToPromise = (stream, action_count = 1) => stream.take(action_count).toArray().toPromise();

describe('routeExternal', () => {
  const action$ = Rx.Observable.never();
  const store_router = {
    stripUrlBase: (a) => a,
    navigateOrReload: jest.fn()
  };

  afterEach(() => {
    delete global.Minibar;
  });

  describe('delivery address present', () => {
    const destination = '/store/category/wine';
    const initial_state = address_factory.stateify(address_factory.build());
    const store = createMBStore(initial_state);

    beforeEach(() => {
      actionStream.mockReturnValue(Rx.Observable.of({destination}));
    });

    it('dispatches nothing but routes within the store if it has store_router', () => {
      global.Minibar = store_router;

      expect.hasAssertions();
      return routeExternal(action$, store).let(flattenToPromise).then((actions) => {
        expect(actions).toEqual([]);
        expect(ui_utils.enterStore).not.toHaveBeenCalled();
        expect(store_router.navigateOrReload).toHaveBeenCalledWith(destination, {trigger: true});
      });
    });

    it('dispatches nothing but routes into the store if does not have store_router', () => {
      global.Minibar = undefined;

      expect.hasAssertions();
      return routeExternal(action$, store).let(flattenToPromise).then((actions) => {
        expect(actions).toEqual([]);
        expect(ui_utils.enterStore).toHaveBeenCalledWith(destination);
        expect(store_router.navigateOrReload).not.toHaveBeenCalled();
      });
    });
  });

  describe('delivery address not present', () => {
    const store = createMBStore({});

    it('dispatches a show_delivery_info action if has store_router and destination is not externally navigable', () => {
      global.Minibar = store_router;

      const destination = '/store/category/wine';
      actionStream.mockReturnValue(Rx.Observable.of({destination}));

      expect.hasAssertions();
      return routeExternal(action$, store).let(flattenToPromise).then((actions) => {
        expect(actions).toEqual([ui_actions.showDeliveryInfoModal(destination)]);
        expect(ui_utils.enterStore).not.toHaveBeenCalled();
        expect(store_router.navigateOrReload).not.toHaveBeenCalled();
      });
    });

    it('dispatches a show_delivery_info action if does not have store_router and destination is not externally navigable', () => {
      global.Minibar = undefined;

      const destination = '/store/category/wine';
      actionStream.mockReturnValue(Rx.Observable.of({destination}));

      expect.hasAssertions();
      return routeExternal(action$, store).let(flattenToPromise).then((actions) => {
        expect(actions).toEqual([ui_actions.showDeliveryInfoModal(destination)]);
        expect(ui_utils.enterStore).not.toHaveBeenCalled();
        expect(store_router.navigateOrReload).not.toHaveBeenCalled();
      });
    });

    it('dispatches nothing but routes within the store if has store_router and destination is externally navigable', () => {
      global.Minibar = store_router;

      const destination = '/store/product/sixpoint-crisp';
      actionStream.mockReturnValue(Rx.Observable.of({destination}));

      expect.hasAssertions();
      return routeExternal(action$, store).let(flattenToPromise).then((actions) => {
        expect(actions).toEqual([]);
        expect(ui_utils.enterStore).not.toHaveBeenCalled();
        expect(store_router.navigateOrReload).toHaveBeenCalledWith(destination, {trigger: true});
      });
    });

    it('dispatches nothing but enters the store if does not have store_router and destination is externally navigable', () => {
      global.Minibar = undefined;

      const destination = '/store/product/sixpoint-crisp';
      actionStream.mockReturnValue(Rx.Observable.of({destination}));

      expect.hasAssertions();
      return routeExternal(action$, store).let(flattenToPromise).then((actions) => {
        expect(actions).toEqual([]);
        expect(ui_utils.enterStore).toHaveBeenCalledWith(destination);
        expect(store_router.navigateOrReload).not.toHaveBeenCalled();
      });
    });
  });
});

describe('showDeliveryInfo', () => {
  const actions = [
    makeSuccessAction('SUPPLIER:REFRESH_SUPPLIERS')()
  ];

  actions.forEach(action => {
    describe(`handles ${action.type}`, () => {

      // No longer true for marketplace
      // const action$ = Rx.Observable.of(action);

      // it('returns a show_delivery_info action when suppliers default to non on_demand delivery methods and the user has not been shown suppliers', () => {
      //   const suppliers = [
      //     supplier_factory.build({delivery_methods: [dm_factory.build({type: 'on_demand'})]}),
      //     supplier_factory.build({delivery_methods: [dm_factory.build({type: 'pickup'}), dm_factory.build({type: 'on_demand'})]})
      //   ];
      //   const initial_state = {
      //     ...supplier_factory.stateify(suppliers),
      //     ui: { delivery_info_shown_for_suppliers: false }
      //   };
      //   const store = createMBStore(initial_state);

      //   expect.assertions(1);
      //   return expect(showDeliveryInfo(action$, store).let(flattenToPromise))
      //     .resolves.toEqual([ui_actions.showDeliveryInfoModal()]);
      // });

      // it('returns nothing when the user has been shown their suppliers, even if some suppliers default to non on_demand delivery methods', () => {
      //   const suppliers = [
      //     supplier_factory.build({delivery_methods: [dm_factory.build({type: 'on_demand'})]}),
      //     supplier_factory.build({delivery_methods: [dm_factory.build({type: 'pickup'}), dm_factory.build({type: 'on_demand'})]})
      //   ];
      //   const initial_state = {
      //     ...supplier_factory.stateify(suppliers),
      //     ui: { delivery_info_shown_for_suppliers: true }
      //   };
      //   const store = createMBStore(initial_state);

      //   expect.assertions(1);
      //   return expect(showDeliveryInfo(action$, store).let(flattenToPromise))
      //     .resolves.toEqual([]);
      // });

      // it('returns nothing when all suppliers default to on_demand delivery, even if they have not been shown to the user', () => {
      //   const suppliers = [
      //     supplier_factory.build({delivery_methods: [dm_factory.build({type: 'on_demand'})]}),
      //     supplier_factory.build({delivery_methods: [dm_factory.build({type: 'on_demand'}), dm_factory.build({type: 'pickup'})]})
      //   ];
      //   const initial_state = {
      //     ...supplier_factory.stateify(suppliers),
      //     ui: { delivery_info_shown_for_suppliers: false }
      //   };
      //   const store = createMBStore(initial_state);

      //   expect.assertions(1);
      //   return expect(showDeliveryInfo(action$, store).let(flattenToPromise))
      //     .resolves.toEqual([]);
      // });
    });
  });
});
