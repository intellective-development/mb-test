import React, { Component, createContext } from 'react';
import {
  BrandSelect,
  ProductTypeSelect,
  ProductGroupingSelect,
  BundleTypeSelect
} from 'admin/admin_select';

const BundleSourceContext = createContext();

export default class BundleSource extends Component {
  constructor(props) {
    super(props);

    const {bundle_source} = props;
    const selectedType = bundle_source.type
    const selectedSource = bundle_source.source_id && parseInt(bundle_source.source_id);
    this.state = {
      selectedType,
      selectedSource: [selectedSource]
    };
  }

  sourceTypeChange = (sourceType) => {
    const { value } = sourceType;
    this.setState({
      selectedType: value,
      selectedSource: undefined
    });
  };

  render () {
    const {selectedType, selectedSource} = this.state;
    return (
      <BundleSourceContext.Provider value={{sourceTypeChange: this.sourceTypeChange}}>
        <fieldset>
          <legend>
            Bundle Source - Item that will trigger the bundling
          </legend>
          <BundleTypeSelect
            initialValueIds={[selectedType]}
            selectedValues={[selectedType]}
            name="bundle[source_type]"
            label="Source Type"
            onChange={this.sourceTypeChange}
            placeholder="select source type" />
          {selectedType == 'Brand' &&
            <BrandSelect
              initialValueIds={selectedSource}
              name="bundle[source_id]"
              placeholder="Select a brand" />
          }
          {selectedType == 'ProductType' &&
            <ProductTypeSelect
              initialValueIds={selectedSource}
              name="bundle[source_id]"
              placeholder="Select a product type" />
          }
          {selectedType == 'ProductSizeGrouping' &&
            <ProductGroupingSelect
              initialValueIds={selectedSource}
              name="bundle[source_id]"
              placeholder="Select a product" />
          }
        </fieldset>
      </BundleSourceContext.Provider>
    );
  }
}
