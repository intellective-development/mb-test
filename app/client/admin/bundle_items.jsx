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

    const {bundleItems} = props;
    this.state = {
      bundleItems: bundleItems || []
    };
  }

  sourceTypeChange = (sourceType, index) => {
    const {bundleItems} = this.state;
    const { value } = sourceType;
    bundleItems[index].item_type = value;
    bundleItems[index].item_id = null;
    this.setState({
      bundleItems
    });
  };

  addBundleItem = () => {
    const {bundleItems} = this.state;
    bundleItems.push({});
    this.setState({
      bundleItems
    });
  }

  removeBundleItem = (index) => {
    const {bundleItems} = this.state;
    bundleItems.splice(index, 1);
    this.setState({
      bundleItems
    });
  }

  render () {
    const {bundleItems} = this.state;
    return (
      <BundleSourceContext.Provider value={{sourceTypeChange: this.sourceTypeChange}}>
        <fieldset>
          <legend>
            Bundle items - Options that will be suggested when the source is selected - <a role="button" tabIndex={0} className="add_child" onClick={this.addBundleItem}>Add Bundle Item</a>
          </legend>

          {bundleItems.map((bundleItem, index) => {
            let initialIds = [];
            if (bundleItem.item_id) {
              initialIds = [parseInt(bundleItem.item_id)];
            }
            return (
              <fieldset key={index} className="wrapper">
                <BundleTypeSelect
                  initialValueIds={[bundleItem.item_type]}
                  selectedValues={[bundleItem.item_type]}
                  name={`bundle[item_type][]`}
                  label={`Item Type ${index > 0 && index || ''}`}
                  onChange={(source) => this.sourceTypeChange(source, index)}
                  placeholder="select item type" />
                {bundleItem.item_type == 'Brand' &&
                  <BrandSelect
                    initialValueIds={initialIds}
                    name={`bundle[item_id][]`}
                    label={`Brand Filter ${index > 0 && index || ''}`}
                    id={`brand_${index}`}
                    placeholder="Select a brand" />
                }
                {bundleItem.item_type == 'ProductType' &&
                  <ProductTypeSelect
                    initialValueIds={initialIds}
                    name={`bundle[item_id][]`}
                    id={`product_type_${index}`}
                    label={`Product Type Filter ${index > 0 && index || ''}`}
                    placeholder="Select a product type" />
                }
                {bundleItem.item_type == 'ProductSizeGrouping' &&
                  <ProductGroupingSelect
                    initialValueIds={initialIds}
                    name={`bundle[item_id][]`}
                    id={`product_grouping_${index}`}
                    label={`Product Filter ${index > 0 && index || ''} `}
                    placeholder="Select a product" />
                }
                {index > 0 &&
                  <a className="danger" tabIndex={index} onClick={() => { this.removeBundleItem(index) }}>Remove</a>
                }
              </fieldset>
            )
          })}

        </fieldset>
      </BundleSourceContext.Provider>
    );
  }
}
