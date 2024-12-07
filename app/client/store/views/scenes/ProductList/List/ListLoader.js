// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { product_list_actions } from 'store/business/product_list';

import ScrollSensor from 'shared/components/visible_sensor_component';
import { MBTouchable } from '../../../elements';

type ListLoaderProps = {
  product_list_id: string,
  list_fetching: boolean,
  all_list_items_loaded: boolean,

  // DTP
  requestNextPage: typeof product_list_actions.requestNextPage
}
class ListLoader extends React.Component<ListLoaderProps> {
  getProducts = () => {
    if (this.props.list_fetching) return null;

    this.props.requestNextPage(this.props.product_list_id);
  }


  handleScrollerVisibleChange = (visible: boolean) => {
    if (visible){
      this.getProducts();
    }
  }

  render(){
    const { list_fetching, all_list_items_loaded } = this.props;
    if (all_list_items_loaded) return null;

    return (
      <ScrollSensor onChange={this.handleScrollerVisibleChange} bottomOffset={300}>
        <div className="product-list-load-more center">
          <MBTouchable id="list-more" className="control" onClick={this.getProducts}>
            {list_fetching ? 'Loading...' : 'Show More'}
          </MBTouchable>
        </div>
      </ScrollSensor>
    );
  }
}

const ListLoaderDTP = {requestNextPage: product_list_actions.requestNextPage};

export default connect(null, ListLoaderDTP)(ListLoader);
