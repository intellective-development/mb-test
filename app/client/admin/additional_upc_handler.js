// @flow

import React, { Component } from 'react';
import _ from 'lodash';
import getCSRFToken from 'admin/utils/csrf_token';

type AdditionalUpcHandlerProps = {
  product_id: number,
  upc: string,
  isAdd: Boolean
};

const closeModal = () => {
  document.location.reload(true);
};

const SameUpcProductsSelect = ({products, validateSelectedProduct, onClick}) => {
  let title = 'Select products you want to remove this UPC from.';
  if (products.length === 0){
    title = 'There are no other products using this additional UPC.';
  }
  return (
    <div>
      <h5>{title}</h5>
      <ul className="small-block-grid-3">
        {products.map((product, _index) => (
          <ProductCheckbox key={product.id} name={`${product.name} - ${product.item_volume}`} value={product.id} checked={validateSelectedProduct(product.id)} onClick={onClick} />
        ))}
      </ul>
    </div>
  );
};

const ProductCheckbox = ({name, value, checked, onClick}) => (
  <li>
    <label htmlFor={`check-${value}`}>
      <input id={`check-${value}`} type="checkbox" value={value} checked={checked} onChange={onClick} /> {name}
    </label>
  </li>
);

class AdditionalUpcHandler extends Component {
  props: AdditionalUpcHandlerProps
  static requestHeaders(){
    return {
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': getCSRFToken()
      }
    };
  }
  constructor(props){
    super(props);
    this.state = {
      upc: '',
      loading: false,
      submitting: false,
      showOtherProducts: false,
      products: [],
      selectedProducts: [],
      results: null
    };
  }
  componentDidMount(){
    if (this.props.upc){
      this.fetchProductsSameUpc();
    }
  }
  fetchProductsSameUpc(){
    const self = this;
    self.setState({loading: true});

    fetch(`/admin/merchandise/products/${this.props.product_id}/find_products_with_upc?upc=${this.state.upc || this.props.upc}`, {
      ...AdditionalUpcHandler.requestHeaders()
    }).then(response => response.json())
      .then(data => {
        self.setState({products: data, loading: false, showOtherProducts: true});
      });
  }
  onUpcChange(event){
    this.setState({upc: event.target.value});
  }
  _onUpdateSelectedProducts(event){
    this.setState({selectedProducts: _.xor(this.state.selectedProducts, [event.target.value])});
  }
  _validateSelectedProduct(product){
    return this.state.selectedProducts.includes(product.toString());
  }
  _saveAdditionalUpcs(){
    const self = this;
    self.setState({submitting: true});

    let method = 'add_additional_upc';
    if (!this.props.isAdd){
      method = 'remove_additional_upc';
    }

    fetch(`/admin/merchandise/products/${this.props.product_id}/${method}`, {
      ...AdditionalUpcHandler.requestHeaders(),
      method: 'POST',
      body: JSON.stringify({
        upc: this.state.upc || this.props.upc,
        products_to_remove: this.state.selectedProducts
      })
    }).then(response => response.json())
      .then(data => {
        self.setState({submitting: false});
        if (data.success && ((data.results && data.results.length > 0) || (data.errors && data.errors.length > 0))){
          self.setState({results: data.results, errors: data.errors});
        } else {
          document.location.reload(true);
        }
      });
  }
  render(){
    const saveButtonLabel = this.props.isAdd ? 'Save' : 'Remove';
    const submittingButtonLabel = this.props.isAdd ? 'Saving...' : 'Removing...';
    const results = this.state.results;
    const errors = this.state.errors;
    if (((results && results.length > 0) || (errors && errors.length > 0)) && !this.props.isAdd){
      return (
        <div>
          <h4>Additional UPC removal results</h4>
          {results.map((result, _index) => (
            <div key={result.original_product.id} className="flex-row">
              <div className="flex-item">
                <span>Original Product name: {result.original_product.name}</span>
              </div>
              {(!result.errors || result.errors.length === 0) && (
                <div className="flex-item">
                  <span>New Product name: <a target="blank" href={`/admin/merchandise/products/${result.new_product.id}/edit`}> {result.new_product.name} </a></span>
                </div>
              )}
              {result.errors && result.errors.length > 0 && (
                <div className="flex-item">
                  <span>Errors: {result.errors.join(', ')} </span>
                </div>
              )}
            </div>
          ))}
          {errors.length > 0 && (
            <h5>Errors removing additional UPCs</h5>
          )}
          {errors.map((error, _index) => (
            <div key={error} className="flex-row">
              <div className="flex-item">
                <span>Error: {error}</span>
              </div>
            </div>
          ))}
          <br />
          <div className="flex-row">
            <div className="flex-item">
              <button onClick={closeModal} className="button">Close</button>
            </div>
          </div>
        </div>
      );
    }
    return (
      <div>
        {!this.props.isAdd && this.state.products && this.state.products.length === 0 && (
          <p>Are you sure you want to remove this additional UPC?</p>
        )}
        {this.props.isAdd && (
          <div className="flex-row">
            <div className="flex-item">
              <label htmlFor={'upc'}>UPC</label>
              <input id={'upc'} type="text" value={this.state.upc} onChange={this.onUpcChange.bind(this)} />
            </div>
          </div>
        )}
        {this.state.showOtherProducts && (
          <SameUpcProductsSelect
            products={this.state.products}
            onClick={this._onUpdateSelectedProducts.bind(this)}
            validateSelectedProduct={this._validateSelectedProduct.bind(this)} />
        )}
        {this.props.isAdd && (
          <div className="flex-row">
            <div className="flex-item">
              <button onClick={this.fetchProductsSameUpc.bind(this)} className="button neutral">Check Product Using the same UPC</button>
            </div>
          </div>
        )}
        <div className="flex-row">
          <div className="flex-item">
            <button disabled={this.state.submitting} onClick={this._saveAdditionalUpcs.bind(this)} className="button">{this.state.submitting ? submittingButtonLabel : saveButtonLabel}</button>
          </div>
        </div>
      </div>
    );
  }
}

export default AdditionalUpcHandler;
