// @flow

import React from 'react';
import _ from 'lodash';

type SizeSelectorProps = {
  volumes: Array,
  selected: ?String,
  onSelect: ?Function,
};

const getUnitCode = (selected) => {
  switch (true){
    case (/GAL$/i).test(selected):
      return 'GLL';
    case (/ML$/i).test(selected):
      return 'MLT';
    case (/L$/i).test(selected):
      return 'LTR';
    case (/OZ$/i).test(selected):
      return 'OZA';
    default:
      return 'MLT';
  }
};

class SizeSelector extends React.PureComponent<SizeSelectorProps> {
  onSelect = (e) => {
    this.props.onSelect(e.target.value);
  }
  getSizeElements = () => {
    const { volumes } = this.props;
    const selected = this.props.selected || volumes[0];

    if (volumes.length === 1){
      return (
        <React.Fragment>
          <meta
            content={getUnitCode(selected)}
            itemProp="unitCode" />
          <span
            content={parseInt(selected)}
            itemProp="value">
            {selected}
          </span>
        </React.Fragment>
      );
    } else {
      return (
        <select
          className="select--brand select--pdp select--pdp--size"
          content={getUnitCode(selected)}
          id="product-size"
          itemProp="unitCode"
          onChange={this.onSelect}
          value={selected}>
          {volumes.map(volume => (
            <option
              content={parseInt(volume)}
              itemProp="value"
              key={volume}
              value={volume}>
              {volume}
            </option>
          ))}
        </select>
      );
    }
  }
  render(){
    const { volumes } = this.props;
    if (_.isEmpty(volumes)) return null;
    const only_one = volumes.length === 1 ? 'cursor_default' : '';

    return (
      <div
        className="variant_volume"
        itemProp="weight"
        itemScope
        itemType="https://schema.org/QuantitativeValue">
        <label className={only_one} htmlFor="product-size">Size: </label>
        {this.getSizeElements()}
      </div>
    );
  }
}

export default SizeSelector;
