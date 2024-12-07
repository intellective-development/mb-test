import PropTypes from 'prop-types';
import * as React from 'react';
import {
  BrandSelect
} from 'admin/admin_select';

// TODO: BC: move this height calc to admin select with chars per
// line and height increase as props, also strip out of invoice
// recipient select bootstraping
const CHARS_PER_LINE = 20;
const HEIGHT_INCREASE_ON_WRAP = 8;
// options become larger as text wraps
const CALCULATE_OPTION_HEIGHT = (obj) => {
  let height = 24;
  const text = obj.option.name || obj.option.label; // 'name' for API options, 'label' for static options
  height += (Math.floor(text.length / CHARS_PER_LINE) * HEIGHT_INCREASE_ON_WRAP);
  return height;
};

const PromotedFacetFiltersBrand = ({
  initialBrandIds = [],
  name = 'facet_filter[brand_0][]',
  multi = true
}) => (
  <div>
    <BrandSelect
      initialValueIds={initialBrandIds}
      name={name}
      placeholder="Brand"
      optionHeight={CALCULATE_OPTION_HEIGHT}
      multi={multi} />
  </div>
);

PromotedFacetFiltersBrand.propTypes = {
  initialBrandIds: PropTypes.array,
  name: PropTypes.string,
  multi: PropTypes.bool
};

export default PromotedFacetFiltersBrand;
