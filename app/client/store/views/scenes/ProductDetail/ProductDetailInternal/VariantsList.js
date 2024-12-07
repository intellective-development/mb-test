// @flow
import React from 'react';
import type { Variant } from 'store/business/variant';
import VariantItem from './VariantItem';

type VariantsListProps = {
  productGrouping: Object,
  variants: Array<Variant>,
};

const VariantsList = ({ variants, productGrouping }: VariantsListProps) => (
  <div className="variant-list-wrapper">
    {variants.map(variant => (
      <VariantItem
        productGrouping={productGrouping}
        variant={variant} />
    ))}
  </div>
);

export default VariantsList;
