// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';

import type { Filter } from 'store/business/filter';
import { product_list_helpers } from 'store/business/product_list';
import type { ProductList } from 'store/business/product_list';
import type { ExternalProductGrouping } from 'store/business/product_grouping';

import FullPageLoader from 'shared/components/full_page_loader';
import ProductListItemExternal from './List/ListItemExternal';
import { ListWrapper, injectPromotions } from './List/ListWrapper';
import UnavailableMessage from './UnavailableMessage';

type ProductListExternalProps = {
  product_list_id: string,
  product_list: ProductList,
  filter: Filter,

  // STP
  product_groupings: ExternalProductGrouping[]
};

const ProductListExternal = ({product_list_id, product_list, filter, product_groupings}: ProductListExternalProps) => {
  const list_empty = product_list_helpers.isEmpty(product_list);
  const list_fetching = product_list_helpers.isProductListFetching(product_list);
  const list_is_loading = !product_list || !filter || (list_fetching && list_empty);
  const promotions = product_list_helpers.getPromotionsForList(product_list);

  if (list_is_loading){
    return <FullPageLoader />;
  } else {
    return (
      <ListWrapper
        product_list={product_list}
        product_list_id={product_list_id}>
        {list_empty && !list_fetching ? <UnavailableMessage filter={filter} /> : injectPromotions(promotions, product_groupings.map(product_grouping => (
          <ProductListItemExternal product_grouping={product_grouping} key={`product_${product_grouping.id}`} />
        )))}
      </ListWrapper>
    );
  }
};

const ProductListExternalSTP = () => {
  const findProductGroupings = Ent.query(Ent.find('product_grouping'), Ent.join('external_products'));

  return (state, {product_list}) => ({
    product_groupings: findProductGroupings(state, product_list_helpers.getProductIdsForList(product_list))
  });
};

const ProductListExternalContainer = connect(ProductListExternalSTP)(ProductListExternal);

export default ProductListExternalContainer;
