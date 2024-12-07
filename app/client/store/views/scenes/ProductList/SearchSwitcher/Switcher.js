// @flow

import * as React from 'react';
import formatCurrency from 'shared/utils/format_currency';

import { delivery_method_helpers } from 'store/business/delivery_method';
import type { DeliveryMethod } from 'store/business/delivery_method';
import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';
import { variant_helpers } from 'store/business/variant';
import type { Supplier } from 'store/business/supplier';

import { MBTouchable } from '../../../elements';
import {
  ProductListItemImage,
  ProductListItemPropertyTag,
  ProductListItemPropertyName,
  ProductListItemPropertyType,
  ProductListItemPropertyVolume,
  ProductListItemPropertyPrice
} from '../List/ProductListItemProperties';

type SwitcherProps = {
  product_groupings: ProductGrouping[],
  supplier: Supplier,
  delivery_method: DeliveryMethod,
  requestChangeSupplier: (permalink?: string) => void
};
const Switcher = ({product_groupings, supplier, delivery_method, requestChangeSupplier}: SwitcherProps) => {
  const handleClick = () => { requestChangeSupplier(); }; // don't pass the event to requestChangeSupplier
  const column_count = (product_groupings.length + 1) * 3;
  const product_tiles = product_groupings.map(product_grouping => (
    <ProductTile product_grouping={product_grouping} requestChangeSupplier={requestChangeSupplier} key={product_grouping.id} />
  ));

  return (
    <div className={`search-switch-wrapper small-12 medium-${column_count} columns dark-panel`}>
      <h6 className="heading-metadata">Top results from <strong>{supplier.name}</strong></h6>
      <ul className="grid-product__container grid-product__container--switch">
        {product_tiles}
        <li className="grid-product grid-product--switch grid-product--switch--supplier">
          <MBTouchable className="grid-product__contents" onClick={handleClick}>
            <h5 className="title grid-product__property--store-name">{supplier.name}</h5>
            <p className="body--small grid-product__property--delivery-estimate">
              {delivery_method_helpers.formatNextDelivery(delivery_method, {include_type: true})}
            </p>
            <hr />
            <p className="body--small grid-product__property--switch">Switch to {supplier.name} to view more results</p>
            <span className="button expand small add-to-cart">Switch Stores</span>
          </MBTouchable>
        </li>
      </ul>
    </div>
  );
};

const ProductTile = ({product_grouping, requestChangeSupplier}) => {
  const variant = variant_helpers.defaultVariant(product_grouping.variants);
  const handleClick = (e) => {
    e.preventDefault();
    requestChangeSupplier(`/store/product/${product_grouping.permalink}`);
  };

  return (
    <li className="grid-product grid-product--browse grid-product--switch grid-product--switch--product">
      <a
        className="grid-product__contents"
        href={`/store/product/${product_grouping.permalink}`}
        onClick={handleClick}
        data-category="product placement">
        <ProductListItemImage src={product_grouping_helpers.getThumb(product_grouping, variant)} alt={product_grouping.name} />
        <div className="grid-product__property-container">
          <ProductListItemPropertyTag propVal={product_grouping_helpers.primaryTag(product_grouping)} />
          <ProductListItemPropertyName propVal={product_grouping.name} />
          <ProductListItemPropertyType propVal={product_grouping_helpers.getProductType(product_grouping).name} shouldRender={product_grouping.hierarchy_category.name === 'wine'} />
          <ProductListItemPropertyVolume propVal={variant.volume} shouldRender={!!variant.volume} />
          <ProductListItemPropertyPrice propVal={formatCurrency(variant.price)} />
        </div>
      </a>
    </li>
  );
};

export default Switcher;
