import external_product_factory from '../../external_product/__tests__/external_product.factory';
import variant_factory from '../../variant/__tests__/variant.factory';
import product_grouping_factory from './product_grouping.factory';
import {
  primaryTag,
  fullPermalink
} from '../helpers';

describe('primaryTag', () => {
  it('returns a formatted string for the highest priority tag a product has assigned to it', () => {
    const product_grouping = product_grouping_factory.build({tags: ['flash_deal', 'category_feature']});
    expect(primaryTag(product_grouping)).toEqual('Flash Deal');
  });

  it('returns nothing if a product has no whitelisted tags', () => {
    const product_grouping = product_grouping_factory.build({tags: ['other_tag']});
    expect(primaryTag(product_grouping)).toEqual('');
  });
});

describe('fullPermalink', () => {
  it('returns a formatted permalink', () => {
    const product_grouping = product_grouping_factory.build({permalink: 'dogfish-head'});

    expect(fullPermalink(product_grouping)).toEqual('/store/product/dogfish-head');
  });

  it('returns a formatted permalink (with variant) if a variant is passed', () => {
    const product_grouping = product_grouping_factory.build({permalink: 'dogfish-head'});
    const variant = variant_factory.build({permalink: 'dogfish-head-12oz-cans'});

    expect(fullPermalink(product_grouping, variant)).toEqual('/store/product/dogfish-head/dogfish-head-12oz-cans');
  });

  it('returns a formatted permalink (with external_product) if a external_product is passed', () => {
    const product_grouping = product_grouping_factory.build({permalink: 'dogfish-head'});
    const external_product = external_product_factory.build({permalink: 'dogfish-head-12oz-cans'});

    expect(fullPermalink(product_grouping, external_product)).toEqual('/store/product/dogfish-head/dogfish-head-12oz-cans');
  });
});

