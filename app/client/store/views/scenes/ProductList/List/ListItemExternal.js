// @flow

import * as React from 'react';

import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ExternalProductGrouping } from 'store/business/product_grouping';
import { external_product_helpers } from 'store/business/external_product';

import { MBLink } from '../../../elements';
import {
  ProductListItemImage,
  ProductListItemPropertyName,
  ProductListItemPropertyTag,
  ProductListItemPropertyType
} from './ProductListItemProperties';
import MoreDetails from '../../../../../product_browse/MoreDetailsPrompt';

type ListItemExternalProps = {
  product_grouping: ExternalProductGrouping
};

const ListItemExternal = ({product_grouping}: ListItemExternalProps) => {
  const external_product = external_product_helpers.defaultExternalProduct(product_grouping);

  return (
    <li className="grid-product grid-product--browse">
      <MBLink.View
        className="grid-product__contents"
        href={product_grouping_helpers.fullPermalink(product_grouping, external_product)}>
        <ProductListItemImage src={product_grouping_helpers.getThumb(product_grouping, external_product)} alt={product_grouping.name} />
        <ProductListItemPropertyTag propVal={null} />
        <ProductListItemPropertyName propVal={product_grouping.name} />
        <ProductListItemPropertyType propVal={product_grouping_helpers.getProductType(product_grouping).name} shouldRender={product_grouping.hierarchy_category.name === 'wine'} />
      </MBLink.View>
      <div className="actions">
        <MoreDetails href={product_grouping_helpers.fullPermalink(product_grouping, external_product)} />
      </div>
    </li>
  );
};

export default ListItemExternal;
