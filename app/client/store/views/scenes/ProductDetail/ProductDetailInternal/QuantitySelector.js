// @flow

import React from 'react';
import _ from 'lodash';

const MAX_QUANTITY_DEFAULT = 24;
type QuantitySelectorProps = {
  value: number,
  current_variant: Variant,
  handleChange: Function
};
class QuantitySelector extends React.PureComponent<QuantitySelectorProps> {
  handleChange = (e) => {
    this.props.handleChange(parseInt(e.target.value));
  }

  render(){
    const max_quantity = Math.min(this.props.current_variant.in_stock, MAX_QUANTITY_DEFAULT) + 1;
    const quantity_range = _.range(1, max_quantity);

    return (
      <div className="small-12 columns">
        <select
          value={this.props.value}
          id="product-quantity"
          className="select--brand select--pdp select--pdp--quantity"
          onChange={this.handleChange}>
          {quantity_range.map(index => (
            <option value={index} key={index}>{index}</option>
          ))}
        </select>
      </div>
    );
  }
}

export default QuantitySelector;
