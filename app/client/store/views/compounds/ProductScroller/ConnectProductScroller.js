// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import { content_layout_actions } from 'store/business/content_layout';
import { request_status_selectors, request_status_constants } from 'store/business/request_status';
import type { RequestStatus } from 'store/business/request_status';

type ProductScrollerProps = {
  content_module_id: string,
  title?: string,
  content_url?: string,
  action_url?: string,
  internal_name?: string,
  // From STP & DTP
  product_loading_state: RequestStatus,
  content_module_products: Array<ProductGrouping>,
  loadProductGroupings: typeof content_layout_actions.fetchContentModuleProducts
}

function connectProductScroller(WrappedComponent: React.ComponentType<*>){
  class ProductScrollerContainer extends React.Component<ProductScrollerProps> {
    static defaultProps = {
      content_module_products: []
    }

    componentDidMount(){
      if (_.isEmpty(this.props.content_module_products)){
        this.props.loadProductGroupings(this.props.content_url, this.props.content_module_id);
      }
    }

    render(){
      const { action_url, content_module_products, title, product_loading_state, ...other_props } = this.props;

      return (
        <WrappedComponent
          action_url={action_url}
          product_groupings={content_module_products}
          products_loaded={product_loading_state === request_status_constants.SUCCESS_STATUS}
          title={title}
          {...other_props} />
      );
    }
  }

  return connect(ProductScrollerSTP, ProductScrollerDTP)(ProductScrollerContainer);
}

const ProductScrollerSTP = () => {
  const findProductVariants = Ent.query(Ent.find('product_grouping'), Ent.join('variants'));

  return (state, { product_ids, content_module_id }) => ({
    content_module_products: findProductVariants(state, product_ids),
    suppliers: state.supplier.by_id,
    cart_items: Object.values(state.cart_item.by_id),
    product_loading_state: request_status_selectors.getRequestStatusByAction(state, 'CONTENT_LAYOUT:FETCH_PRODUCTS', content_module_id)
  });
};

const ProductScrollerDTP = {
  loadProductGroupings: content_layout_actions.fetchContentModuleProducts
};

export default connectProductScroller;
