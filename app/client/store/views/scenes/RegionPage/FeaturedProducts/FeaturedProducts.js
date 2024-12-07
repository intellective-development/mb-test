import { css } from '@amory/style/umd/style';
import React from 'react';
import ProductScroller from '../../../compounds/ProductScroller/index';

import featured from './featured.json';

export const FeaturedProducts = ({ name }) =>
  (
    <div className={css({ marginTop: 80 })}>
      <ProductScroller
        product_groupings={featured.product_groupings}
        products_loaded
        title={`Featured Products in ${name}`} />
    </div>
  );

export default FeaturedProducts;
