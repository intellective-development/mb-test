// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import classNames from 'classnames';
import formatCurrency from 'shared/utils/format_currency';
import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';
import { variant_helpers } from 'store/business/variant';
import { analytics_helpers, analytics_actions } from 'store/business/analytics';

import { makeComponentAbleToAdd } from 'product_browse/AddToCart'; // TODO this uses the old event system
import {
  CartPlacementTransitioner,
  SmallAddToCartButton
} from 'cart/cart_shared';
import {
  ProductListItemImage,
  ProductListItemPropertyName,
  ProductListItemPropertyVolume,
  ProductListItemPropertyPrice
} from 'store/views/scenes/ProductList/List/ProductListItemProperties';
import SelectableList from 'cart/selectable_list';

const SMALL_VISIBLE_PRODUCT_COUNT = 3;
const LARGE_VISIBLE_PRODUCT_COUNT = 6;

type MeetMinimumPlacementProps = {
  title?: string,
  content_url?: string,
  action_url?: string,
  shipment: Object,
  product_groupings: Array<ProductGrouping>
}

type MeetMinimumPlacementState = {
  showing_more: boolean
}

const MeetMinimumPlacement = class extends React.Component<MeetMinimumPlacementProps, MeetMinimumPlacementState> {
  state = { showing_more: false }

  toggleVisibleProductCount = (e: Event) => {
    e.preventDefault();
    this.setState({ showing_more: !this.state.showing_more });
  };

  render(){
    const { product_groupings, shipment } = this.props;

    if (_.isEmpty(product_groupings)) return null;

    const visible_product_count = this.state.showing_more ? LARGE_VISIBLE_PRODUCT_COUNT : SMALL_VISIBLE_PRODUCT_COUNT;

    return (
      <td colSpan="5" className="cart-placement__container">
        <h4 className="heading-cart cart-placement__header--minimum">
          Easy Extras at {shipment.supplier.name}
        </h4>
        <SelectableList
          items={product_groupings}
          display_count={visible_product_count}
          renderContainer={(content) => (
            <CartPlacementTransitioner className="grid-product__container--cart--minimum">
              {content}
            </CartPlacementTransitioner>
          )}
          renderItem={(item, selectItem) => (
            <MeetMinimumItem
              onClick={selectItem}
              placement={{ content: product_groupings }}
              product_grouping={item}
              variant={variant_helpers.defaultVariant(item.variants)}
              visibleProductCount={visible_product_count}
              key={item.id}
              target="cart_meet_minimum_placement"
              tracking_identifier="cart_meet_minimum_placement" />
          )} />
        <ShowMoreLink open={this.state.showing_more} toggleVisibleProductCount={this.toggleVisibleProductCount} />
      </td>
    );
  }
};


class MeetMinimumItemClass extends React.PureComponent {
  componentDidMount(){
    const { product_grouping, variant, trackEvent } = this.props;
    trackEvent({
      action: 'product_appeared_in_meet_minimum',
      content_type: 'product',
      items: [analytics_helpers.getItemData(product_grouping, variant)]
    });
  }

  onClick(e){
    const { onClick, addToCart } = this.props;
    onClick();
    addToCart(e);
  }

  render(){
    const { product_grouping, variant, buttonLifecycleState } = this.props;
    return (<li
      className={`grid-product grid-product--cart--minimum grid-product--cart--${buttonLifecycleState}`}
      onClick={this.onClick.bind(this)}>
      <div className="grid-product--cart--minimum__contents">
        <ProductListItemImage src={product_grouping_helpers.getThumb(product_grouping, variant)} alt={product_grouping.name} />
        <div className="grid-product__contents__subcontainer">
          <ProductListItemPropertyName propVal={product_grouping.name} />
          <ProductListItemPropertyVolume propVal={variant.volume} shouldRender={!!variant.volume} />
          <ProductListItemPropertyPrice price={formatCurrency(variant.price)} originalPrice={formatCurrency(variant.original_price)} />
        </div>
        <SmallAddToCartButton buttonLifecycleState={buttonLifecycleState} />
      </div>
    </li>);
  }
}

const MeetMinimumItemClassDTP = {
  trackEvent: analytics_actions.track
};

const MeetMinimumItem = makeComponentAbleToAdd(connect(null, MeetMinimumItemClassDTP)(MeetMinimumItemClass));

const ShowMoreLink = ({ open, toggleVisibleProductCount }) => {
  const classes = classNames('cart-placement__show-more--minimum', { open });
  const content = open ? 'Less' : 'More';
  return <a className={classes} href="#" onClick={toggleVisibleProductCount}>{content}</a>;
};

export default MeetMinimumPlacement;
