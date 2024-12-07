import PropTypes from 'prop-types';
import * as React from 'react';
import VirtualizedSelect from 'react-virtualized-select';
import { fetchSellables } from 'admin/admin_api';
import {
  BrandSelect,
  ProductTypeSelect,
  SupplierSelect,
  ProductSelect
} from 'admin/admin_select';

const arrayToOptions = (array) => (
  array.map((item) => ({label: item[0], value: item[1]}))
);

class SellableModule extends React.Component {
  static propTypes = {
    initialType: PropTypes.string,
    sellableTypes: PropTypes.array,
    initialSellables: PropTypes.array,
    name: PropTypes.string,
    couponId: PropTypes.number
  };

  constructor(props){
    super(props);
    this.state = { selectedType: this.props.initialType, isInitialType: true };
  }

  onTypeChange = (type) => {
    this.setState({
      selectedType: type.value,
      isInitialType: (type.value === this.props.initialType)
    });
  };

  sellableTypeOptions = () => {
    return arrayToOptions(this.props.sellableTypes);
  };

  initialOptions = () => {
    return this.state.isInitialType ? fetchSellables(this.props.initialType, this.props.initialSellables, this.props.couponId) : null;
  };

  sellableSelect = () => {
    switch (this.state.selectedType){
      case 'Brand':
        return (
          <BrandSelect
            key={'Brand'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Brands:"
            multi />
        );
      case 'ProductType':
        return (
          <ProductTypeSelect
            key={'ProductType'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Product Types:"
            multi />
        );
      case 'Supplier':
        return (
          <SupplierSelect
            key={'Supplier'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Suppliers:"
            multi />
        );
      case 'Product':
        return (
          <ProductSelect
            key={'Product'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Products:"
            multi />
        );
      case 'Variant':
        return 'Variant';
      case null:
        return '';
      case 'All':
        return (
          <div className="sellable-select-component__all-message">Coupon valid universally.</div>
        );
      default:
        return 'Select A Type';
    }
  };

  testSelect = () => {
    switch (this.state.selectedType){
      case 'Brand':
        return (
          <BrandSelect
            key={'Brand'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Brands:"
            multi />
        );
      case 'ProductType':
        return (
          <ProductTypeSelect
            key={'ProductType'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Product Types:"
            multi />
        );
      case 'Supplier':
        return (
          <SupplierSelect
            key={'Supplier'}
            initialValuesPromise={this.initialOptions()}
            name={`${this.props.name}[sellable_ids][]`}
            label="Restricted to Following Suppliers:"
            multi />
        );
      case 'Variant':
        return 'Variant';
      case null:
        return '';
      case 'All':
        return (
          <div className="sellable-select-component__all-message">Coupon valid universally.</div>
        );
      default:
        return 'Select A Type';
    }
  };

  render(){
    return (
      <div className="row">
        <div className="large-3 columns">
          <label htmlFor="sellable-select_{this.state.selectedType}">
            Type
            <VirtualizedSelect
              id="sellable-select_{this.state.selectedType}"
              value={this.state.selectedType}
              options={this.sellableTypeOptions()}
              onChange={this.onTypeChange}
              name={`${this.props.name}[sellable_type]`}
              clearable={false} />
          </label>
        </div>
        <div className="large-9 columns">
          <div key={this.state.selectedType}>{this.sellableSelect()}</div>
        </div>
      </div>
    );
  }
}

export default SellableModule;
