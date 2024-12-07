import React from 'react';
import { isEmpty } from 'lodash';
import { product_list_helpers } from 'store/business/product_list';

/* ::
import type { Filter } from 'store/business/filter';
import type { ProductList } from 'store/business/product_list';
*/

import { MBErrorBoundary } from '../../../elements/MBErrorBoundary';
import { FacetBar } from './FacetBar';

/* ::
type FacetBarProps = {
  filter?: Filter,
  product_list?: ProductList,
  product_list_id: string
};
*/

const FacetBarIndex = ({
  filter,
  'product_list': productList,
  'product_list_id': productListId
} /* : FacetBarProps */) => {
  if (isEmpty(filter) || isEmpty(productList)){
    return null;
  }

  const facets = product_list_helpers.getFacetsForList(productList);
  const productCount = product_list_helpers.productListTotal(productList);
  const sortOptionId = product_list_helpers.getSortForList(productList);

  return (
    <MBErrorBoundary
      errorData={() => ({
        facets,
        filter,
        location: 'FacetBar',
        productCount,
        productListId,
        sortOptionId
      })}>
      <FacetBar
        facets={facets}
        filter={filter}
        productCount={productCount}
        productListId={productListId}
        sortOptionId={sortOptionId} />
    </MBErrorBoundary>
  );
};

export { FacetBarIndex as FacetBar };
