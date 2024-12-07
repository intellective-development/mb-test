// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { variant_helpers } from 'store/business/variant';
import { product_grouping_helpers } from 'store/business/product_grouping';
import { refreshShopRunnerContent } from 'shared/utils/shop_runner';

import type { ProductGrouping } from 'store/business/product_grouping';

import makeContentLayout from '../../GenericContentLayout';
import ProductBreadcrumbs from '../Breadcrumbs';
import ProductSchema from '../ProductSchema';
import StoreDeliveryList from './StoresDeliveryList';
import {
  ProductDetailContainer,
  ProductBrand,
  ProductName,
  ProductDescription,
  ProductProperties
} from '../ProductDetailElements';


import '../index.scss';

type ProductDetailInternalProps = {|
  product_grouping: ProductGrouping,
  default_variant_permalink?: string,

  viewContent: typeof ui_actions.viewContent
  // HOC
  //TODO: trackEvent: typeof analytics_actions.track
|};
type ProductDetailInternalState = { current_variant: Variant };
class ProductDetailInternal extends React.PureComponent<ProductDetailInternalProps, ProductDetailInternalState> {
  componentDidMount(){
    refreshShopRunnerContent();
  }

  render(){
    const { default_variant_permalink, product_grouping } = this.props;

    return (
      <React.Fragment>
        <ProductBreadcrumbs product_grouping={product_grouping} />
        <ProductDetailContainer
          renderImage={() => (
            <img
              alt={product_grouping.name}
              itemProp="image"
              src={product_grouping_helpers.getImage(
                product_grouping,
                variant_helpers.defaultVariant(product_grouping.variants)
              )} />
          )}
          renderBody={() => (
            <React.Fragment>
              <ProductBrand product_grouping={product_grouping} />
              <ProductName product_grouping={product_grouping} />
              <StoreDeliveryList
                {...product_grouping}
                default_variant_permalink={default_variant_permalink} />
              <ProductDescription product_grouping={product_grouping} />
              <ProductProperties product_grouping={product_grouping} />
            </React.Fragment>
          )} />
        <PDPContentLayout context={{ product_grouping_id: product_grouping.permalink }} />
        <ProductSchema product_grouping={product_grouping} variant_permalink={default_variant_permalink} />
      </React.Fragment>
    );
  }
}

const PDPContentLayout = makeContentLayout('Web_PDP_Content_Screen');

const ProductDetailInternalDTP = {
  //trackEvent: analytics_actions.track
};

export default connect(null, ProductDetailInternalDTP)(ProductDetailInternal);
