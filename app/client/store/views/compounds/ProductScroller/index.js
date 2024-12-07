// @flow

import * as React from 'react';
import I18n from 'store/localization';
import _ from 'lodash';
import bindClassNames from 'shared/utils/bind_classnames';
import { MBHeader, MBLayout, MBGrid } from '../../elements';
import ProductTile from './ProductTile';
import ProductLoadingTile from './ProductLoadingTile';
import styles from './ProductScroller.scss';

const cn = bindClassNames(styles);

type ProductScrollerProps = {
  title?: string,
  action_url?: string,
  internal_name?: string,
  // From HOC
  product_groupings: Array<ProductGrouping>,
  products_loaded: boolean
}

const empty_product_array = Array(6).fill(ProductLoadingTile).map((TileConstructor, index) => (<TileConstructor key={index} />));

const ProductScroller = ({ action_url, internal_name, product_groupings, products_loaded, title }: ProductScrollerProps) => {
  if (_.isEmpty(product_groupings) && products_loaded) return null;

  const image_tiles = products_loaded ? (
    product_groupings.map(product_grouping => (
      <ProductTile
        key={product_grouping.id}
        product_grouping={product_grouping}
        internal_name={internal_name}
        className={cn('cmProductScroller_Tile')} />
    ))
  ) : empty_product_array;

  return (
    <MBLayout.StandardGrid className={cn('cmProductScroller')}>
      <MBHeader
        title={title}
        action_url={action_url}
        action_name={I18n.t('ui.content_modules.product_scroller.action_name')} />
      <MBGrid cols={2} medium_cols={4} large_cols={6}>
        {image_tiles}
      </MBGrid>
    </MBLayout.StandardGrid>
  );
};

export default ProductScroller;
