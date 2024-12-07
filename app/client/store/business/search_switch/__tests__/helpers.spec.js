import search_switch_factory from './search_switch.factory';
import {
  getProductGroupingIds,
  getSupplierId,
  isEmpty
} from '../helpers';


describe('getProductGroupingIds', () => {
  it('returns search switch\'s product_grouping_ids', () => {
    const product_grouping_ids = ['a', 'b'];
    const search_switch = search_switch_factory.build({product_grouping_ids});
    expect(getProductGroupingIds(search_switch)).toBe(product_grouping_ids);
  });
});

describe('getSupplierId', () => {
  it('returns search switch\'s supplier_id', () => {
    const supplier_id = 10;
    const search_switch = search_switch_factory.build({supplier_id});

    expect(getSupplierId(search_switch)).toBe(supplier_id);
  });
});

describe('isEmpty', () => {
  it('returns false if the search_switch has product_grouping_ids and a supplier_id', () => {
    const product_grouping_ids = ['a', 'b'];
    const supplier_id = 10;
    const search_switch = search_switch_factory.build({product_grouping_ids, supplier_id});
    expect(isEmpty(search_switch)).toBe(false);
  });

  it('returns true otherwise', () => {
    const product_grouping_ids = [];
    const supplier_id = null;
    const search_switch = search_switch_factory.build({product_grouping_ids, supplier_id});
    expect(isEmpty(search_switch)).toBe(true);
  });
});
