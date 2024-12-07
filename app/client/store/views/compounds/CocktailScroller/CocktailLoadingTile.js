// @flow

import * as React from 'react';
import classNames from 'classnames';
import bindClassNames from 'shared/utils/bind_classnames';
import styles from './CocktailScroller.scss';

const cn = bindClassNames(styles);

const ProductLoadingTile = () => {
  return (
    <li className={cn('cmProductScroller_Tile')}>
      <div className={classNames('grid-product__contents grid-product__contents--loading')}>
        <img
          className={cn('cmProductScroller__LoadingImage')}
          src={'/assets/components/compounds/product_scroller/bottle_outline.png'}
          srcSet={'/assets/components/compounds/product_scroller/bottle_outline@2x.png 2x, ' +
            '/assets/components/compounds/product_scroller/bottle_outline@3x.png 3x'}
          alt="product loading placeholder" />
        <div className={cn('cmProductScroller__LoadingText')} />
        <div className={cn('cmProductScroller__LoadingText')} />
      </div>
    </li>
  );
};

export default ProductLoadingTile;
