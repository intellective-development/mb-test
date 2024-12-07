// @flow

import * as React from 'react';
import { get, compact, has, map, max, min } from 'lodash-es';
import { product_grouping_helpers, Property } from 'store/business/product_grouping';
import type { ExternalProduct } from 'store/business/external_product';
import type { ProductGrouping } from 'store/business/product_grouping';
import type { Variant } from 'store/business/variant';

import JsonLD from '../../compounds/JsonLD';

type ProductSchemaProps = {
  product_grouping: ProductGrouping,
  variant_permalink?: String,
  external_product?: ExternalProduct
};
const ProductSchema = ({product_grouping, variant_permalink, external_product}: ProductSchemaProps) => {
  return (
    <JsonLD data={formatProductSchema(product_grouping, variant_permalink, external_product)} />
  );
};

export default ProductSchema;

const BASE_URL = 'https://minibardelivery.com';
const formatProductSchema = (product_grouping: ProductGrouping, variant_permalink: ?String, external_product: ?ExternalProduct) => {
  let product_data;

  if (external_product){
    product_data = {
      'offers': formatPriceRange(external_product),
      'image': formatImage(product_grouping, external_product),
      'url': `${BASE_URL}/store/product/${product_grouping.permalink}/${external_product.permalink}`,
      '@id': `${BASE_URL}/store/product/${product_grouping.permalink}/${external_product.permalink}`
    };
  } else if (get(product_grouping, 'variants')){
    product_data = {
      'offers': formatVariants(product_grouping),
      'image': formatImage(product_grouping, {permalink: variant_permalink}),
      'url': `${BASE_URL}/store/product/${product_grouping.permalink}/${variant_permalink}`,
      '@id': `${BASE_URL}/store/product/${product_grouping.permalink}/${variant_permalink}`
    };
  } else {
    product_data = {
      'image': formatImage(product_grouping),
      'url': `${BASE_URL}/store/product/${product_grouping.permalink}`,
      '@id': `${BASE_URL}/store/product/${product_grouping.permalink}`
    };
  }

  return {
    '@context': 'http://schema.org',
    '@type': 'Product',
    'description': get(product_grouping, 'description', ''),
    'name': get(product_grouping, 'name'),
    'audience': {
      '@type': 'PeopleAudience',
      'requiredMinAge': 21
    },
    'brand': formatBrand(product_grouping),
    'category': formatCategory(product_grouping),
    'additionalProperty': formatProperties(product_grouping),
    ...product_data
  };
};

const formatBrand = (product_grouping) => {
  if (!product_grouping.brand_data.name) return null;

  return ({
    '@type': 'Brand',
    'name': product_grouping.brand_data.name,
    'url': `${BASE_URL}/store/brand/${String(product_grouping.brand_data.permalink)}`
  });
};

const formatProperties = (product_grouping: ProductGrouping) => {
  return map(get(product_grouping, 'properties'), (property: Property) => ({
    '@type': 'PropertyValue',
    'name': get(property, 'name'),
    'value': get(property, 'value')
  }));
};

const formatCategory = (product_grouping: ProductGrouping) => {
  return compact([
    {
      '@type': 'Thing',
      'name': get(product_grouping, 'hierarchy_category.name'),
      'url': [
        BASE_URL,
        'store/category',
        get(product_grouping, 'hierarchy_category.permalink')
      ].join('/')
    },
    has(product_grouping, 'hierarchy_type.name')
      ? {
        '@type': 'Thing',
        'name': get(product_grouping, 'hierarchy_type.name'),
        'url': [
          BASE_URL,
          'store/category',
          get(product_grouping, 'hierarchy_category.permalink'),
          get(product_grouping, 'hierarchy_type.permalink')
        ].join('/')
      }
      : null,
    has(product_grouping, 'hierarchy_subtype.name')
      ? {
        '@type': 'Thing',
        'name': get(product_grouping, 'hierarchy_subtype.name'),
        'url': [
          BASE_URL,
          'store/category',
          get(product_grouping, 'hierarchy_category.permalink'),
          get(product_grouping, 'hierarchy_type.permalink'),
          get(product_grouping, 'hierarchy_subtype.permalink')
        ].join('/')
      }
      : null
  ]);
};

const formatImage = (product_grouping: ProductGrouping, product?: ExternalProduct | Variant) => ({
  '@context': 'http://schema.org',
  '@type': 'ImageObject',
  'caption': product_grouping.name,
  'name': product_grouping.name,
  'contentUrl': product_grouping_helpers.getImage(product_grouping, product)
});

const formatVariants = (product_grouping: ProductGrouping) => {
  const variants = get(product_grouping, 'variants', []);
  const offerCount = variants.length;

  if (offerCount === 0) return null;

  if (offerCount > 1){
    const highPrice = max(map(variants, 'price'));
    const lowPrice = min(map(variants, 'price'));
    return map(variants, (variant: Variant) => ({
      '@type': 'AggregateOffer',
      'name': 'container',
      'priceCurrency': 'USD',
      'highPrice': highPrice,
      'identifier': get(variant, 'container_type'),
      'lowPrice': lowPrice,
      'price': get(variant, 'price'),
      'offerCount': offerCount
    }));
  }

  const variant = variants[0];
  return {
    '@type': 'Offer',
    'name': 'container',
    'availability': 'http://schema.org/InStock',
    'priceCurrency': 'USD',
    'identifier': get(variant, 'container_type'),
    'price': get(variant, 'price'),
    'url': `${BASE_URL}/store/product/${product_grouping.permalink}/${get(variant, 'permalink')}`
  };
};

const formatPriceRange = (external_product: ExternalProduct) => ({
  '@type': 'AggregateOffer',
  'availability': 'http://schema.org/InStock',
  'priceCurrency': 'USD',
  'offerCount': 1,
  'identifier': get(external_product, 'permalink'),
  'highPrice': get(external_product, 'max_price'),
  'lowPrice': get(external_product, 'min_price')
});
