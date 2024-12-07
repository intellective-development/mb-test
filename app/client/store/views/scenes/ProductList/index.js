// @flow

import React, { useEffect, useRef } from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';

import { filter_helpers } from 'store/business/filter';
import type { Filter } from 'store/business/filter';
import { product_list_actions, product_list_constants } from 'store/business/product_list';
import type { ProductList } from 'store/business/product_list';
import { session_selectors } from 'store/business/session';
import { supplier_selectors } from 'store/business/supplier';
import { address_selectors } from 'store/business/address';

import FullPageLoader from 'shared/components/full_page_loader';
import makeContentLayout from '../GenericContentLayout';
import ProductListExternal from './ProductListExternal';
import ProductListInternal from './ProductListInternal';
import { withUniqueId } from '../../elements';

const { INTERNAL_LIST_TYPE, EXTERNAL_LIST_TYPE } = product_list_constants;

type ProductListProductListSceneProps = {
  // WUI
  product_list_id: string,

  // CO
  location?: { params: { filter?: Filter, sort?: product_list_constants.SortOptionId } },

  // STP
  product_list?: ProductList,
  filter?: Filter,
  has_checked_for_suppliers: boolean,
  has_current_suppliers: boolean,

  // DTP
  createProductList: typeof product_list_actions.createProductList,
  removeFilter: typeof product_list_actions.removeFilter,
};

/* TODO:
  componentWillUnmount(){
    this.props.removeFilter(this.props.product_list_id);
  }*/
const ProductListScene = ({
  filter,
  product_list,
  product_list_id,
  has_checked_for_suppliers,
  /* added props */
  location,
  createProductList,
  has_current_suppliers
}: ProductListProductListSceneProps) => {
  const locRef = useRef();
  useEffect(() => {
    if (has_checked_for_suppliers && locRef.current !== location.identifier){
      locRef.current = location.identifier;
      createProductList(product_list_id, {
        filter: location.filter,
        sort_option_id: location.sort,
        type: has_current_suppliers ? INTERNAL_LIST_TYPE : EXTERNAL_LIST_TYPE
      });
    }
  }, [location, has_checked_for_suppliers, has_current_suppliers]);

  if (!has_checked_for_suppliers || !product_list) return <FullPageLoader />;

  const ProductListComponent = product_list.type === EXTERNAL_LIST_TYPE ? ProductListExternal : ProductListInternal;

  return (
    <div className="store-browse__content">
      <ProductListContentLayout filter={filter} />
      <ProductListComponent
        product_list_id={product_list_id}
        product_list={product_list}
        filter={filter} />
    </div>
  );
};

const ProductListContentLayout = ({ filter }) => {
  if (!filter) return null;

  const context = filter_helpers.baseFilter(filter);
  switch (filter.base){
    case 'brand':
      return <BrandContentLayout context={context} can_fetch_without_suppliers />;
    case 'reorder':
      return <ReorderContentLayout context={context} can_fetch_without_suppliers suppress_loading />;
    case 'tag':
      return <PromoContentLayout context={context} can_fetch_without_suppliers suppress_loading />;
    case 'promo_list':
      return <PromoContentLayout context={context} can_fetch_without_suppliers suppress_loading />;
    case 'list_type':
      return <ListTypeContentLayout context={context} can_fetch_without_suppliers suppress_loading />;
    default:
      return null;
  }
};
const BrandContentLayout = makeContentLayout('Web_Brand_PLP_Screen');
const PromoContentLayout = makeContentLayout('Web_Promo_PLP_Screen');
const ReorderContentLayout = makeContentLayout('Web_Reorder_PLP_Screen');
const ListTypeContentLayout = makeContentLayout('Web_List_Type_PLP_Screen');

const ProductListSceneSTP = () => {
  const findList = Ent.find('product_list');
  const findFilter = Ent.find('filter');

  return (state, { product_list_id, location }) => {
    return ({
      location,
      product_list: findList(state, product_list_id),
      filter: findFilter(state, product_list_id),
      has_checked_for_suppliers: session_selectors.hasCheckedForSuppliers(state),
      has_current_suppliers: address_selectors.currentDeliveryAddressId(state) && supplier_selectors.hasCurrentSuppliers(state)
    });
  };
};

const ProductListSceneDTP = {
  createProductList: product_list_actions.createProductList,
  removeFilter: product_list_actions.removeFilter
};

const ProductListSceneContainer = connect(ProductListSceneSTP(), ProductListSceneDTP)(ProductListScene);

export default withUniqueId('product_list_id')(ProductListSceneContainer);

export const __private__ = {
  ProductListSceneContainer
};
