// @flow

import type { Action } from '@minibar/store-business/src/constants';

export const noSupplierRefresh = (): Action => ({
  type: 'SESSION:NO_SUPPLIER_REFRESH'
});

export const reloadProductGroupings = (): Action => ({
  type: 'SESSION:RELOAD_PRODUCT_GROUPINGS'
});
