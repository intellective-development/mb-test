// @flow

import * as React from 'react';
import _ from 'lodash';
import { variant_helpers } from '@minibar/store-business/src/variant';
import { product_grouping_helpers } from '@minibar/store-business/src/product_grouping';
import { product_grouping_helpers as web_product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';
import classNames from 'classnames';
import formatCurrency from 'shared/utils/format_currency';
import { MBLink } from 'store/views/elements';
import {
  ProductListItemPropertyName,
  ProductListItemImage,
  ProductListItemPropertyPrice,
  ProductListItemPropertyVolume
} from '../../scenes/ProductList/List/ProductListItemProperties';
import MoreDetails from '../../../../product_browse/MoreDetailsPrompt';

type ProductTileProps = {|
  product_grouping: ProductGrouping,
  show_anonymous: boolean,
  internal_name?: string
|};

const ProductTileAction = ({ show_anonymous, product_grouping }: ProductTileProps) => {
  let action;
  if (show_anonymous){
    action = <MoreDetails href={web_product_grouping_helpers.fullPermalink(product_grouping)} />;
  } else {
    action = <MoreDetails product_grouping={product_grouping} />;
  }
  return action;
};

const ProductTileContents = ({ show_anonymous, product_grouping }: ProductTileProps) => {
  let image;
  let name;
  let volume;
  let price;
  let has_discount;

  if (show_anonymous){
    image = <ProductListItemImage src={product_grouping.thumb_url} alt={product_grouping.name} />;
    name = <ProductListItemPropertyName propVal={product_grouping.name} />;
  } else {
    const variant = variant_helpers.defaultVariant(product_grouping.variants);
    has_discount = variant.original_price !== variant.price;

    image = <ProductListItemImage src={product_grouping_helpers.getThumb(product_grouping, variant)} alt={product_grouping.name} />;
    name = <ProductListItemPropertyName propVal={product_grouping.name} />;
    volume = <ProductListItemPropertyVolume propVal={variant.volume} shouldRender={!!variant.volume} />;
    price = <ProductListItemPropertyPrice price={formatCurrency(variant.price)} originalPrice={formatCurrency(variant.original_price)} />;
  }

  const classes = classNames('grid-product__contents', {
    discounted: has_discount
  });

  return (
    <MBLink.View className={classes} href={web_product_grouping_helpers.fullPermalink(product_grouping)} data-category="product placement" native_behavior={show_anonymous}>
      {image}
      {name}
      {volume}
      {price}
    </MBLink.View>
  );
};

const ProductTile = ({ product_grouping, className, internal_name }: ProductTileProps) => {
  const show_anonymous = _.isEmpty(product_grouping.variants);
  const wrapper_class = classNames('grid-product grid-product--featured', {
    'grid-product--featured--anonymous': show_anonymous
  }, className);

  return (
    <li className={wrapper_class}>
      <div className="actions">
        <ProductTileAction
          show_anonymous={show_anonymous}
          product_grouping={product_grouping}
          internal_name={internal_name} />
      </div>
      <ProductTileContents
        show_anonymous={show_anonymous}
        product_grouping={product_grouping} />
    </li>
  );
};

export default ProductTile;
