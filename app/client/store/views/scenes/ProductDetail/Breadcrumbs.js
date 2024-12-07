// @flow

import * as React from 'react';
import _ from 'lodash';
import type { ProductGrouping } from 'store/business/product_grouping';

import BrowseBreadcrumbs, { formatProductTypeDestination } from '../../compounds/BrowseBreadcrumbs';
import { MBLayout } from '../../elements';
import JsonLD from '../../compounds/JsonLD';

import styles from './index.scss';

type BreadcrumbsProps = {
  product_grouping: ProductGrouping
};
const Breadcrumbs = ({product_grouping}: BreadcrumbsProps) => {
  const { hierarchy_category, hierarchy_type, hierarchy_subtype } = product_grouping;
  if (!hierarchy_category) return null;

  const breadcrumbs = [
    {description: 'home', destination: '/store/'},
    {description: hierarchy_category.name, destination: formatProductTypeDestination(hierarchy_category.permalink)},
    {description: hierarchy_type.name, destination: formatProductTypeDestination(hierarchy_category.permalink, hierarchy_type.permalink)},
    {description: hierarchy_subtype.name, destination: formatProductTypeDestination(hierarchy_category.permalink, hierarchy_type.permalink, hierarchy_subtype.permalink)}
  ].filter(({description, destination}) => description && destination);

  return (
    <MBLayout.StandardGrid className={styles.scPDP_BreadcrumbContainer}>
      <BrowseBreadcrumbs breadcrumbs={breadcrumbs} />
      <JsonLD data={formatBreadcrumbSchema(breadcrumbs)} />
    </MBLayout.StandardGrid>
  );
};

export default Breadcrumbs;

const formatBreadcrumbSchema = (breadcrumb_data: Array<{description: string, destination: string}>) => ({
  '@context': 'http://schema.org',
  '@type': 'BreadcrumbList',
  'itemListElement': breadcrumb_data.map(({description, destination}, index) => ({
    '@type': 'ListItem',
    'position': index + 1,
    'item': {
      '@type': 'WebPage',
      '@id': `https://minibardelivery.com${destination}`,
      'name': _.startCase(description)
    }
  }))
});
