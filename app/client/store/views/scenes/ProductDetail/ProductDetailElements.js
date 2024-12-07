// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import type { ProductGrouping, Deal } from 'store/business/product_grouping';
import { address_selectors } from 'store/business/address';

import * as Ent from '@minibar/store-business/src/utils/ent';

import { MBLink, MBText, MBTooltip } from '../../elements';

type ProductDetailContainerProps = {renderImage(): React.Node, renderBody(): React.Node }
export const ProductDetailContainer = ({renderImage, renderBody}: ProductDetailContainerProps) => {
  return (
    <div
      className="row"
      itemScope
      itemType="https://schema.org/Product">
      <div className="large-6 medium-5 column product-image center">
        {renderImage()}
      </div>
      <div className="large-6 medium-7 small-12 column product-actions">
        {renderBody()}
      </div>
    </div>
  );
};

type ProductBrandProps = {product_grouping: ProductGrouping};
export const ProductBrand = ({product_grouping}: ProductBrandProps) => {
  if (!product_grouping.brand_data.permalink) return null;

  return (
    <MBText.H2
      className="product-detail__brand-name"
      itemProp="brand">
      <MBLink.View
        href={`/store/brand/${product_grouping.brand_data.permalink}`}>
        {product_grouping.brand_data.name}
      </MBLink.View>
    </MBText.H2>
  );
};

type ProductNameProps = {product_grouping: ProductGrouping};
export const ProductName = ({product_grouping}: ProductNameProps) => (
  <MBText.H1
    className="product-detail__product-name"
    itemProp="name"
    reset_spacing={false}>
    <MBLink.View
      href={`/store/product/${product_grouping.permalink}`}
      itemProp="url">
      {product_grouping.product_name}
    </MBLink.View>
  </MBText.H1>
);

type DealListProps = {deals: Deal[]};
export const DealList = ({deals}: DealListProps) => {
  if (_.isEmpty(deals)) return null;

  return (
    <div>
      {deals.map(deal => <DealInfo deal={deal} key={deal.short_title} />)}
    </div>
  );
};

type DealInfoProps = {deal: Deal};
const DealInfo = ({deal}: DealInfoProps) => {
  if (!deal.long_title) return null;
  return (
    <div className="pdp-deal">
      <h5 className="pdp-deal__heading">Special Offer</h5>
      <p className="pdp-deal__description">
        {deal.long_title}
        &nbsp;
        <MBTooltip
          tooltip_text={'Discount will be automatically applied at checkout. \n May be combined with other discounts.'}>
          See Details
        </MBTooltip>
      </p>
    </div>
  );
};

type ProductDescriptionProps = { product_grouping: ProductGrouping }
export const ProductDescription = ({product_grouping}: ProductDescriptionProps) => {
  return (
    <p
      className="p1 product-description"
      itemProp="description">
      {product_grouping.description}
    </p>
  );
};

const ProductPropertiesSTP = state => {
  const findAddress = Ent.find('address');
  const currentAddress = findAddress(state, address_selectors.currentDeliveryAddressId(state)) || {};
  return {
    isCA: currentAddress.state === 'CA'
  };
};

type ProductPropertiesProps = { product_grouping: ProductGrouping, isCA: boolean }
export const ProductProperties = connect(ProductPropertiesSTP)(({product_grouping, isCA}: ProductPropertiesProps) => {
  const property_els = product_grouping.properties.map(property => (
    <tr
      itemProp="additionalProperty"
      itemScope
      itemType="http://schema.org/PropertyValue"
      key={property.name}>
      <th itemProp="name">{property.name}</th>
      <td itemProp="value">{property.value}</td>
    </tr>
  ));

  const pg_type = product_grouping.hierarchy_type;
  return (
    <table className="properties properties--product-detail">
      <tbody>
        {property_els}
        { isCA ?
          <tr>
            <td colSpan="2" className="legal">
              <img className="warning-icon" src="/assets/ui/icon-warning-open.svg" alt="Phone" /> WARNING: This product can expose you to chemicals including Bisphenol A (BPA), which is known to the State of California to cause birth defects or other reproductive harm. For more information go to <a href="https://www.P65Warnings.ca.gov" rel="noopener noreferrer" target="_blank">www.P65Warnings.ca.gov</a>.
            </td>
          </tr>
          : null
        }
        { pg_type && pg_type.name && pg_type.name.toLowerCase() === 'cbd' ?
          <tr>
            <td colSpan="2" className="legal">
              <img className="warning-icon" src="/assets/ui/icon-warning-open.svg" alt="Phone" /> Disclaimer: Information, statements, and reviews regarding products have not been evaluated by the Food and Drug Administration. CBD products are not intended to diagnose, treat, cure or prevent any disease. Minibar Delivery assumes no liability for inaccuracies or misstatements about products.
            </td>
          </tr>
          : null
        }
      </tbody>
    </table>
  );
});

export const UnavailablePanel = ({ permalink }) => (
  <div className="panel__wrapper">
    <div className="panel--unavailable">
      <p className="panel--pdp--message">This product is not available at your address.</p>
      <MBLink.View
        href={`/store/category/${permalink}`}
        className="link-generic button">
        See More
      </MBLink.View>
    </div>
  </div>
);
