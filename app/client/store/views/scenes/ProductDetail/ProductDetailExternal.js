// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import formatCurrency from 'shared/utils/format_currency';
import i18n from 'store/localization';
import { analytics_helpers, analytics_actions } from 'store/business/analytics';
import { external_product_helpers } from 'store/business/external_product';
import type { ExternalProduct } from 'store/business/external_product';
import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';

import { MBText } from '../../elements';
import StoreEntryComponent from '../../compounds/StoreEntry';
import ProductSchema from './ProductSchema';
import ProductBreadcrumbs from './Breadcrumbs';
import {
  ProductDetailContainer,
  ProductBrand,
  ProductName,
  DealList,
  ProductDescription,
  ProductProperties
} from './ProductDetailElements';
import styles from './index.scss';

type ProductDetailExternalProps = {|
  product_grouping: ProductGrouping, // external
  default_external_product_permalink?: string,

  // HOC
  trackEvent: typeof analytics_actions.track
|};
type ProductDetailExternalState = { current_external_product?: ExternalProduct };

class ProductDetailExternal extends React.PureComponent<ProductDetailExternalProps, ProductDetailExternalState> {
  componentDidMount(){
    const { product_grouping } = this.props;
    const current_external_product = this.getCurrentExternalProduct();
    this.props.trackEvent({
      action: 'view_item',
      items: [analytics_helpers.getExternalItemData(product_grouping, current_external_product)]
    });
  }

  getCurrentExternalProduct(){
    const external_product_permalink = String(this.props.default_external_product_permalink);
    const route_product = external_product_helpers.getExternalProduct(this.props.product_grouping.external_products, external_product_permalink);
    return route_product || external_product_helpers.defaultExternalProduct(this.props.product_grouping.external_products) || {};
  }

  render(){
    const { product_grouping } = this.props;
    const current_external_product = this.getCurrentExternalProduct();
    const has_current_external_product = !_.isEmpty(current_external_product);

    return (
      <React.Fragment>
        <ProductBreadcrumbs product_grouping={product_grouping} />
        <ProductDetailContainer
          renderImage={() => (
            <img
              alt={product_grouping.name}
              itemProp="image"
              src={product_grouping_helpers.getImage(
                product_grouping, current_external_product
              )} />
          )}
          renderBody={() => (
            <React.Fragment>
              <ProductBrand product_grouping={product_grouping} />
              <ProductName product_grouping={product_grouping} />
              <SizePricingDescription external_product={current_external_product} />
              <DealList deals={product_grouping.deals} />
              <div className="panel__wrapper">
                <div className="panel--address-entry">
                  <MBText.P className="panel--pdp--message">{i18n.t('ui.product_detail.address_entry_prompt')}</MBText.P>
                  <StoreEntryComponent routing_options={{product_grouping_ids: [product_grouping.id]}} />
                </div>
              </div>
              <ProductDescription product_grouping={product_grouping} />
              <ProductProperties product_grouping={product_grouping} />
            </React.Fragment>
          )} />
        <ProductSchema product_grouping={product_grouping} external_product={has_current_external_product ? current_external_product : undefined} />
      </React.Fragment>
    );
  }
}

type SizePricingDescriptionProps = {external_product?: ExternalProduct};
const SizePricingDescription = ({external_product}: SizePricingDescriptionProps) => {
  if (_.isEmpty(external_product)) return null;

  return (
    <React.Fragment>
      <MBText.P className={styles.scPDP_External_Volume}>{external_product.volume}</MBText.P>
      <MBText.P className={styles.scPDP_External_PriceRange}>
        {formatPriceRange(external_product.min_price, external_product.max_price)}
      </MBText.P>
      <MBText.P className={styles.scPDP_External_AdditionalSizes}>
        {i18n.t('ui.product_detail.additional_sizes')}
      </MBText.P>
    </React.Fragment>
  );
};

const formatPriceRange = (min_price, max_price) => {
  if (min_price === max_price){
    return formatCurrency(min_price);
  } else {
    return `${formatCurrency(min_price)} - ${formatCurrency(max_price)}`;
  }
};

const ProductDetailExternalDTP = {
  trackEvent: analytics_actions.track
};

export default connect(null, ProductDetailExternalDTP)(ProductDetailExternal);
