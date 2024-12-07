// @flow

import * as React from 'react';
import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';

import { MBLoader } from '../../elements';
import ProductBreadcrumbs from './Breadcrumbs';
import {
  ProductDetailContainer,
  ProductBrand,
  ProductName,
  ProductDescription,
  ProductProperties
} from './ProductDetailElements';

type ProductDetailProps = {
  product_grouping: ProductGrouping,
};

const ProductDetailLoading = ({product_grouping}: ProductDetailProps) => {
  return (
    <React.Fragment>
      <ProductBreadcrumbs product_grouping={product_grouping} />
      <ProductDetailContainer
        renderImage={() => (
          <img src={product_grouping_helpers.getImage(product_grouping)} alt={product_grouping.name} />
        )}
        renderBody={() => (
          <React.Fragment>
            <ProductBrand product_grouping={product_grouping} />
            <ProductName product_grouping={product_grouping} />
            <div className="panel__wrapper">
              <div className="panel--loader">
                <MBLoader />
              </div>
            </div>
            <ProductDescription product_grouping={product_grouping} />
            <ProductProperties product_grouping={product_grouping} />
          </React.Fragment>
        )} />
    </React.Fragment>
  );
};

export default ProductDetailLoading;
