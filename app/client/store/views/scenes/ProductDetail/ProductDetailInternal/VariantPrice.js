import React from 'react';
import cn from 'classnames';
import formatCurrency from 'shared/utils/format_currency';

export default ({ variant }) => {
  if (!variant.price) return null;

  const has_discount = variant.price !== variant.original_price;
  const discount_original_classes = cn('discounted__original-price', { hidden: !has_discount });

  return (
    <div>
      <span className="variant_price">
        <meta content="USD" itemProp="priceCurrency" />
        <span
          content={variant.price}
          itemProp="price">
          {formatCurrency(variant.price)}
        </span>
      </span>
      &nbsp;
      <span
        className={discount_original_classes}
        itemProp="priceSpecification"
        itemScope
        itemType="https://schema.org/PriceSpecification">
        <meta content="original price" itemProp="description" />
        <meta content="USD" itemProp="priceCurrency" />
        <span
          content={variant.original_price}
          itemProp="price">
          {formatCurrency(variant.original_price)}
        </span>
      </span>
    </div>
  );
};
