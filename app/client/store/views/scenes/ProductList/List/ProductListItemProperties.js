import * as React from 'react';
import _ from 'lodash';
import classNames from 'classnames';

export const ProductListItemPropertyName = ({propVal}) => (
  <h4 className="grid-product__property grid-product__property--name grid-product__property--main">{propVal}</h4>
);

export const ProductListItemImage = ({src, srcSet, alt}) => (
  <img className="grid-product__image" src={src} srcSet={srcSet} alt={alt} />
);

export const ProductListItemPropertyTag = ({propVal, propDesc}) => {
  const optional_classes = {};
  optional_classes[`grid-product__property--tag--${_.snakeCase(propVal)}`] = propVal;

  const classes = classNames('grid-product__property grid-product__property--tag', optional_classes);
  // for text use propDesc eg. 'By 1, Get 1 for $0.05', or propVal eg. 'sale', if propDesc is null
  return <div className={classes}>{propDesc || propVal}</div>;
};

const ProductListItemPropertyDiscountedFrom = ({price, originalPrice}) => {
  // return nothing if no original price or its the same as the price
  if (!originalPrice || originalPrice === price) return null;

  return (
    <span className="grid-product__property grid-product__property--discount">
      {originalPrice}
    </span>
  );
};

export const ProductListItemPropertyPrice = ({price, originalPrice}) => (
  <h4 className="grid-product__property grid-product__property--price">
    {price} <ProductListItemPropertyDiscountedFrom price={price} originalPrice={originalPrice} />
  </h4>
);

export const ProductListItemPropertyPricesFrom = ({price, originalPrice}) => (
  <h4 className="grid-product__property grid-product__property--price">
    Prices from {price} <ProductListItemPropertyDiscountedFrom price={price} originalPrice={originalPrice} />
  </h4>
);

export const ProductListItemPropertyType = ({propVal, shouldRender}) => {
  const classes = classNames('grid-product__property grid-product__property--type', {
    hidden: !shouldRender
  });
  return <h5 className={classes}>{propVal}</h5>;
};

export const ProductListItemPropertyVolume = ({propVal, shouldRender}) => {
  const header_classes = classNames('grid-product__property grid-product__property--volume', {
    hidden: !shouldRender
  });

  return (
    <h5 className={header_classes}>
      <span className="grid-product__property--volume__value">{propVal}</span>
    </h5>
  );
};

export const ProductListItemPropertyLink = ({propVal, visible}) => {
  const classes = classNames('grid-product__property grid-product__property--link', {
    'grid-product__property--link--hidden': !visible
  });

  return (
    <h4 className={classes}>
      {`${propVal} sizes available \u00BB`}
    </h4>
  );
};

export const ProductListItemDealTag = ({propVal}) => (
  <span className="grid-product__property grid-product__property--deal">
    {propVal.short_title}
  </span>
);

export const ProductListItemSupplier = ({supplier}) => {
  const classes = classNames('grid-product__property grid-product__property--type product-detail__brand-name');
  return <h5 className={classes}>{supplier.name}</h5>;
};
