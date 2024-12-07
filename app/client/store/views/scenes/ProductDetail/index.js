// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import user_selectors from '@minibar/store-business/src/user/selectors';
import isShallowEqualArray from 'shallow-equal/arrays';
import FullPageLoader from 'shared/components/full_page_loader';
import { dispatchAction } from 'shared/dispatcher';
import { supplier_selectors } from 'store/business/supplier';
import { address_selectors } from 'store/business/address';
import { session_selectors } from 'store/business/session';
import { product_grouping_actions, product_grouping_selectors } from 'store/business/product_grouping';
import { ui_actions } from 'store/business/ui';
import type { ProductGrouping } from 'store/business/product_grouping';
import { get } from 'lodash';

import ProductDetailInternal from './ProductDetailInternal';
import ProductDetailExternal from './ProductDetailExternal';
import ProductDetailLoading from './ProductDetailLoading';
import { EmailCapture } from '../LandingPage';

type ProductDetailSceneProps = {|
  product_grouping_permalink: string,
  variant_permalink?: string,

  // HOC
  has_checked_for_suppliers: boolean,
  has_current_suppliers: boolean,
  userIsLoggedIn: boolean,
  product_grouping?: ProductGrouping,
  fetching_product_grouping?: boolean,
  error_fetching_product_grouping?: boolean,
  supplier_ids: number[],
  fetchExternalProduct: typeof product_grouping_actions.fetchExternalProduct,
  fetchProduct: typeof product_grouping_actions.fetchProduct,
  viewContent: typeof ui_actions.viewContent
|};

export class ProductDetailScene extends React.Component<ProductDetailSceneProps> {
  initialProductFetch = (props: ProductDetailSceneProps) => {
    const {
      has_current_suppliers,
      has_checked_for_suppliers,
      fetching_product_grouping,
      product_grouping,
      error_fetching_product_grouping,
      fetchProduct,
      fetchExternalProduct,
      product_grouping_permalink
    } = props;
    const should_fetch = has_checked_for_suppliers && !fetching_product_grouping && !product_grouping;

    if (error_fetching_product_grouping){
      console.warn('Attempted to navigate to a product grouping that could not be found:', product_grouping_permalink);
      dispatchAction({
        actionType: 'navigate',
        destination: '/'
      });
    }
    if (!should_fetch){ return; }

    if (has_current_suppliers){
      fetchProduct(product_grouping_permalink);
    } else {
      fetchExternalProduct(product_grouping_permalink);
    }
  }

  trackViewContent = (product_grouping_id: string) => {
    this.props.viewContent(product_grouping_id);
  }

  componentDidMount(){
    this.initialProductFetch(this.props);

    if (get(this.props, 'product_grouping.original_id', -1) !== -1){
      this.trackViewContent(get(this.props, 'product_grouping.original_id'));
    }
  }

  componentWillReceiveProps(next_props: ProductDetailSceneProps){
    this.initialProductFetch(next_props);

    if (get(this.props, 'product_grouping.original_id') !== get(next_props, 'product_grouping.original_id')){
      this.trackViewContent(get(next_props, 'product_grouping.original_id'));
    }

    if (!isShallowEqualArray(next_props.supplier_ids, this.props.supplier_ids)){
      this.props.fetchProduct(next_props.product_grouping_permalink);
    }
  }

  renderEmailCapture = () => {
    const { userIsLoggedIn } = this.props;
    if (userIsLoggedIn) return null;
    return <EmailCapture />;
  };

  render(){
    const { product_grouping, variant_permalink, has_current_suppliers } = this.props;

    if (!product_grouping){
      return <FullPageLoader />;
    } else if (product_grouping.browse_type === 'INTERNAL' && has_current_suppliers){
      return (
        <React.Fragment>
          <ProductDetailInternal
            product_grouping={product_grouping}
            default_variant_permalink={variant_permalink} />
          {this.renderEmailCapture()}
        </React.Fragment>

      );
    } else if (product_grouping.browse_type === 'EXTERNAL' && !has_current_suppliers){
      return (
        <React.Fragment>
          <ProductDetailExternal
            product_grouping={product_grouping}
            default_external_product_permalink={variant_permalink} />
          {this.renderEmailCapture()}
        </React.Fragment>
      );
    } else {
      // typically, this case will be reached when moving from external -> internal,
      // after the suppliers have been fetched but before the external product grouping has been replaced
      // example props: {has_current_suppliers: true, product_grouping: {type: 'EXTERNAL', ...}}
      return (
        <React.Fragment>
          <ProductDetailLoading product_grouping={product_grouping} />
          {this.renderEmailCapture()}
        </React.Fragment>
      );
    }
  }
}

const ProductDetailSceneSTP = () => {
  const findInternalProductGrouping = Ent.query(Ent.find('product_grouping'), Ent.join('variants'));
  const findExternalProductGrouping = Ent.query(Ent.find('product_grouping'), Ent.join('external_products'));

  return (state, { product_grouping_permalink }) => {
    const has_checked_for_suppliers = session_selectors.hasCheckedForSuppliers(state);
    const has_current_suppliers = address_selectors.currentDeliveryAddressId(state) && supplier_selectors.hasCurrentSuppliers(state);

    let product_grouping;
    let fetching_product_grouping;
    let error_fetching_product_grouping;

    if (has_current_suppliers){
      product_grouping = findInternalProductGrouping(state, product_grouping_permalink);
      fetching_product_grouping = product_grouping_selectors.isProductGroupingFetching(state, product_grouping_permalink);
      error_fetching_product_grouping = product_grouping_selectors.hasProductGroupingFailed(state, product_grouping_permalink);
    } else {
      product_grouping = findExternalProductGrouping(state, product_grouping_permalink);
      fetching_product_grouping = product_grouping_selectors.isExternalProductGroupingFetching(state, product_grouping_permalink);
      error_fetching_product_grouping = product_grouping_selectors.hasExternalProductGroupingFailed(state, product_grouping_permalink);
    }

    return ({
      supplier_ids: supplier_selectors.currentSupplierIds(state),
      has_checked_for_suppliers,
      has_current_suppliers,
      userIsLoggedIn: user_selectors.userIsLoggedIn(state),
      product_grouping,
      fetching_product_grouping,
      error_fetching_product_grouping
    });
  };
};

const ProductDetailSceneDTP = {
  fetchExternalProduct: product_grouping_actions.fetchExternalProduct,
  fetchProduct: product_grouping_actions.fetchProduct,
  viewContent: ui_actions.viewContent
};

const ProductDetailSceneContainer = connect(ProductDetailSceneSTP, ProductDetailSceneDTP)(ProductDetailScene);

export default ProductDetailSceneContainer;
