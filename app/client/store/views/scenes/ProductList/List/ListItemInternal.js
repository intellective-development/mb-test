// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import * as Ent from '@minibar/store-business/src/utils/ent';
import formatCurrency from 'shared/utils/format_currency';
import i18n from 'store/localization';

import classNames from 'classnames';
import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';
import { variant_helpers } from 'store/business/variant';
import { analytics_helpers, analytics_actions } from 'store/business/analytics';
import type { DeliveryMethod } from 'store/business/delivery_method';
import { supplier_selectors } from 'store/business/supplier';
import type { Variant } from 'store/business/variant';

import {
  ProductListItemImage,
  ProductListItemPropertyName,
  ProductListItemPropertyPrice,
  ProductListItemPropertyTag,
  ProductListItemPropertyVolume,
  ProductListItemPropertyLink,
  ProductListItemDealTag
} from './ProductListItemProperties';
import { MBLink } from '../../../elements';
//import AddToCart from '../../../../../product_browse/AddToCart';
import MoreDetails from '../../../../../product_browse/MoreDetailsPrompt';

const getCriteria = ({ container_type, volume }) => {
  const criteria = {};

  if (!_.isEmpty(container_type)){
    criteria.containers = container_type;
  }

  if (!_.isEmpty(volume)){
    criteria.volumes = _.map(
      volume,
      (short_volume) => getMilliliters({ short_volume })
    );
  }

  return criteria;
};

const getMilliliters = ({ short_volume }) => {
  switch (true){
    case (/GAL$/i).test(short_volume):
      return parseFloat(short_volume) * 3785.412;
    case (/ML$/i).test(short_volume):
      return parseFloat(short_volume);
    case (/L$/i).test(short_volume):
      return parseFloat(short_volume) * 1000;
    case (/OZ$/i).test(short_volume):
      return parseFloat(short_volume) * 29.5735;
    default:
      return parseFloat(short_volume);
  }
};

type ListItemInternalProps = {
  show_shipping_warning: boolean;
  product_grouping: ProductGrouping,
  variants: Variant[],
  trackEvent: typeof analytics_actions.track
};

type ListItemInternalState = {
  current_variant: Variant
};

class ListItemInternal extends React.PureComponent<ListItemInternalProps, ListItemInternalState> {
  constructor(props: ListItemInternalProps){
    super(props);

    const criteria = getCriteria(props.filter);
    const variants = _.filter(
      props.variants,
      variant => {
        const volume = getMilliliters(variant);

        const volumeMatch = _.isEmpty(criteria.volumes) || _.includes(criteria.volumes, volume);
        const containerMatch = _.isEmpty(criteria.containers) || _.includes(criteria.containers, variant.container_type);

        return volumeMatch && containerMatch;
      }
    );

    const current_variant = variant_helpers.getDefaultMinVariant({ variants }) || variant_helpers.getDefaultMinVariant({ variants: props.variants });

    this.state = { current_variant };
  }

  componentDidMount = () => {
    const { product_grouping, trackEvent } = this.props;
    const { current_variant } = this.state;
    trackEvent({
      action: 'product_appeared',
      content_type: 'product',
      items: [analytics_helpers.getItemData(product_grouping, current_variant)]
    });
  }

  setVariant = (variant: Variant) => {
    this.setState({current_variant: variant});
  };

  handleClick = () => {
    const { product_grouping, trackEvent } = this.props;
    const { current_variant } = this.state;
    if (current_variant.id){
      trackEvent({
        action: 'select_content',
        content_type: 'product',
        items: [analytics_helpers.getItemData(product_grouping, current_variant)]
      });
    }
  };

  groupVariantsByVolume = () => {
    return _.groupBy(_.sortBy(this.props.variants, getMilliliters), 'volume') || [];
  }

  minimumPriceVariants = () => {
    return _.values(this.groupVariantsByVolume()).map(group => _.minBy(group, 'price'));
  }

  showSizeOptions = (min_variant_count?: number = 1) => {
    const num_sizes = _.size(this.groupVariantsByVolume());
    return num_sizes > min_variant_count && _.isEmpty(this.props.product_grouping.deals);
  };

  showDeals = () => {
    return !_.isEmpty(this.props.product_grouping.deals);
  };

  render(){
    const { product_grouping, show_shipping_warning } = this.props;
    const { current_variant } = this.state;

    if (_.isEmpty(current_variant)){
      return null;
    }

    const has_discount = current_variant.original_price !== current_variant.price;
    const two_for_one_deal = current_variant.deals.length && current_variant.two_for_one;

    let property_tag = '';
    let deal_description = '';
    if (two_for_one_deal){
      property_tag = 'special offer';
      // eg. `Buy 1, Get 1 for $0.05`,
      deal_description = i18n.t('ui.body.product_list.two_for_one_deal', { two_for_one: formatCurrency(Number(two_for_one_deal)) });
    } else if (has_discount){
      property_tag = 'sale';
    } else {
      property_tag = product_grouping_helpers.primaryTag(product_grouping);
    }


    const topLevelClasses = classNames('grid-product grid-product--browse', {
      discounted: has_discount
    });

    const sizes = _.size(this.groupVariantsByVolume());
    return (
      <li className={topLevelClasses}>
        <MBLink.View
          className="grid-product__contents"
          href={product_grouping_helpers.fullPermalink(product_grouping, current_variant)}
          beforeNavigate={this.handleClick}>
          <ProductListItemImage src={product_grouping_helpers.getThumb(product_grouping, current_variant)} alt={product_grouping.name} />
          <ProductListItemPropertyTag propVal={property_tag} propDesc={deal_description} />
          <ProductListItemPropertyName propVal={product_grouping.name} />
          <ProductListItemPropertyVolume propVal={current_variant.volume} shouldRender={!!current_variant.volume} />
          <ProductListItemPropertyPrice price={formatCurrency(current_variant.price)} originalPrice={formatCurrency(current_variant.original_price)} />
          <div className="grid-product__property__hover-wrapper">
            <div className="grid-product__property__hover-wrapper--inactive">
              <ProductListItemPropertyLink propVal={sizes} visible={this.showSizeOptions()} />
            </div>
            {this.showDeals() ?
              <ProductListItemDealTag propVal={_.head(product_grouping.deals)} />
              : null
            }
            {this.showSizeOptions() ?
              <div className="grid-product__property__hover-wrapper--active " >
                <VolumeOptions
                  variants={this.minimumPriceVariants()}
                  should_render={this.showSizeOptions()}
                  current_variant={current_variant}
                  setVariant={this.setVariant} />
              </div>
              : null
            }
          </div>
        </MBLink.View>
        <div className="actions">
          <MoreDetails label={show_shipping_warning ? 'Shipping only' : null} product_grouping={product_grouping} current_variant={current_variant} />
        </div>
      </li>
    );
  }
}

type VolumeOptionsProps = {
  variants: Variant[],
  should_render: boolean,
  current_variant: Variant,
  setVariant(Variant): void
}

const VolumeOptions = ({variants, should_render, current_variant, setVariant}: VolumeOptionsProps) => {
  if (!should_render) return null;

  const elements = variants.map(variant => {
    return (
      <VariantSizeOption
        variant={variant}
        selected={variant.id === current_variant.id}
        key={variant.id}
        setVariant={setVariant} />);
  });

  return (
    <div className="grid-product__property grid-product__property--volume-options">
      {elements}
    </div>
  );
};

class VariantSizeOption extends React.Component<*> {
  handleClick = (e) => {
    e.stopPropagation(); //prevent wrapped link from working its voodoo
    e.preventDefault(); //prevent wrapped link from working its voodoo

    this.props.setVariant(this.props.variant);
  };

  render(){
    const selected_class_name = this.props.selected ? 'property--volume-options__element--selected' : '';
    const volume_short = variant_helpers.formatVolumeShort(this.props.variant);

    if (!volume_short) return null;

    return (
      <div
        role="presentation"
        className={`property--volume-options__element ${selected_class_name}`}
        onClick={this.handleClick}>
        <span className="button grey expand">{volume_short}</span>
      </div>
    );
  }
}

const ListItemInternalDTP = {
  trackEvent: analytics_actions.track
};


const shouldShowShippingWarning = (delivery_methods: DeliveryMethod[]) =>
  !_.compact(delivery_methods).some(({ type }) => type !== 'shipped');

const ListItemInternalSTP = () => {
  const findDeliveryMethod = Ent.find('delivery_method');

  return (state, { product_grouping }) => {
    const delivery_methods = _.map(
      _.map(
        _.map(product_grouping.variants, 'supplier_id'),
        supplier_id => supplier_selectors.supplierSelectedDeliveryMethod(state, supplier_id)
      ),
      delivery_method_id => findDeliveryMethod(state, delivery_method_id)
    );

    return ({
      show_shipping_warning: shouldShowShippingWarning(delivery_methods)
    });
  };
};

export default connect(ListItemInternalSTP, ListItemInternalDTP)(ListItemInternal);
