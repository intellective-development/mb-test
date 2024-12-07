// @flow

import * as React from 'react';
import _ from 'lodash';
import { product_list_constants, product_list_helpers } from 'store/business/product_list';
import type { ProductList } from 'store/business/product_list';
import FullPageLoader from 'shared/components/full_page_loader';
import immutableInsert from '../../../../../utils/immutable_insert';

import { MBLayout } from '../../../elements';
import PromotionListItem from './PromotionListItem';
import ListLoader from './ListLoader';

import { FilterPanel } from '../FilterPanel/index';

type ListWrapperProps = {
  product_list_id: string,
  product_list: ProductList,
  children: React.Node
};
export const ListWrapper = ({ filter, product_list, product_list_id, children }: ListWrapperProps) => {
  const all_list_items_loaded = product_list_helpers.allListItemsLoaded(product_list);
  const facets = _.sortBy(product_list_helpers.getFacetsForList(product_list), 'index');
  const list_fetching = product_list_helpers.isProductListFetching(product_list);

  let listLoader;
  if (list_fetching){
    listLoader = (<FullPageLoader />);
  } else {
    listLoader = (<ListLoader
      all_list_items_loaded={all_list_items_loaded}
      list_fetching={list_fetching}
      product_list_id={product_list_id} />
    );
  }

  return (
    <MBLayout.StandardGrid className="product-list-container">
      <div className="product-list-filters-container">
        <FilterPanel
          facets={facets}
          filter={filter}
          productListId={product_list_id} />
        <div className="list">
          <ul id="products" className={'grid-product__container grid-product__container--browse'}>
            {children}
          </ul>
          {listLoader}
        </div>
      </div>
    </MBLayout.StandardGrid>
  );
};

export const injectPromotions = (promotions: product_list_constants.Promotion[], items: React.Node[]) => {
  // insert any promotions at their specified index
  // We need to sort by position ascending to ensure that later insertions don't shift promotions with higher positions down the list.
  return _.sortBy(promotions, 'position').reduce((list_item_acc, promotion) => {
    const promotion_item = <PromotionListItem promotion={promotion} key={`promo_${String(promotion.name)}`} />;
    return immutableInsert(list_item_acc, promotion.position, promotion_item);
  }, items);
};
