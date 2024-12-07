// @flow

import _ from 'lodash';
import React from 'react';
import { MBTab, MBTablist, MBTabs } from '../../../elements/MBTabs';

const shippingTypeLabels = {
  on_demand: 'Get It Today',
  shipped: 'Shipping',
  vineyard_select: 'Vineyard Select'
};

type ShippingTypeSelectorProps = {
  onSelect: Function,
  selected: ?string,
  shippingTypes: Array<String>
};

const ShippingTypeSelector = ({ onSelect, selected, shippingTypes }: ShippingTypeSelectorProps) => {
  if (_.isEmpty(shippingTypes)){
    return null;
  }
  const className = shippingTypes.length < 2 ? 'cursor_default' : '';

  return (
    <MBTabs selected={selected}>
      <MBTablist className="delivery_methods_tabs">
        {shippingTypes.map((type) => (
          <MBTab
            className={className}
            key={type}
            label={type}
            onClick={() => onSelect(type)}>
            {shippingTypeLabels[type]}
          </MBTab>
        ))}
      </MBTablist>
    </MBTabs>
  );
};

export default ShippingTypeSelector;
