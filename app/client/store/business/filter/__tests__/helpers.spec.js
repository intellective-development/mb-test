import filter_factory from './filter.factory';
import { facetWhitelist } from '../helpers';

describe('facetWhitelist', () => {
  it('returns the whitelist for a query filter', () => {
    const filter = filter_factory.build('search');
    expect(facetWhitelist(filter)).toEqual(['selected_supplier', 'hierarchy_category', 'hierarchy_type', 'hierarchy_subtype', 'country', 'volume', 'container_type', 'delivery_type', 'price']);
  });
});
