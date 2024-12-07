// @flow

import * as React from 'react';
import _ from 'lodash';
import I18n from '../../../../localization';
import { filter_helpers } from '../../../../business/filter';
import type { Filter } from '../../../../business/filter';

import { MBText } from '../../../elements';
import BrowseBreadcrumbs, { formatProductTypeDestination } from '../../../compounds/BrowseBreadcrumbs';
import '../Breadcrumbs/Breadcrumbs.scss';

type FacetBarProps = {
  filter: Filter,
  product_count: number
};
export const Breadcrumbs = ({filter, product_count}: FacetBarProps) => {
  const default_message = I18n.t('ui.product_list.breadcrumbs.default');

  if (filter_helpers.isProductTypeFilter(filter)){
    return <ContextProductType count={product_count} filter={filter} />;
  } else if (filter_helpers.isSearchFilter(filter)){
    return <ContextSearch count={product_count} query={filter.query} />;
  } else if (filter_helpers.isListTypeFilter(filter)){
    const title = I18n.t(`ui.product_list.breadcrumbs.${String(filter.list_type)}`, {defaultValue: default_message});
    return <ContextStaticTitle count={product_count} title={title} />;
  } else {
    const title = I18n.t(`ui.product_list.breadcrumbs.${String(filter.list_type)}`, {defaultValue: default_message});
    return <ContextStaticTitle count={product_count} title={title} />;
  }
};

const ProductCount = ({count}) => {
  return <MBText.Span className="product-count">{_.isNumber(count) ? `(${count})` : ''}</MBText.Span>;
};

const ContextStaticTitle = ({count, title}) => {
  return <MBText.Span>{title} <ProductCount count={count} /></MBText.Span>;
};

const ContextSearch = ({query, count}) => {
  if (count === null) return null;

  const result_string = count === 1 ? 'result' : 'results';
  return <MBText.Span>{count} {result_string} for &ldquo;{query}&rdquo;</MBText.Span>;
};

const ContextProductType = ({filter}) => {
  const { hierarchy_category, hierarchy_type = [], hierarchy_subtype = [] } = filter;

  if (!hierarchy_category) return null;

  const breadcrumbs = [
    { description: 'home', destination: '/store/' },
    {
      description: formatProductTypeDescription(hierarchy_category),
      destination: _.isEmpty(hierarchy_type) ? null : formatProductTypeDestination(hierarchy_category)
    },
    hierarchy_type.map((type_permalink) => ({
      description: formatProductTypeDescription(type_permalink, [hierarchy_category]),
      destination: _.isEmpty(hierarchy_subtype) ? null : formatProductTypeDestination(hierarchy_category, type_permalink)
    })),
    hierarchy_subtype.map((subtype_permalink) => ({
      description: formatProductTypeDescription(subtype_permalink, hierarchy_type),
      destination: null
    }))
  ].filter(breadcrumb => !_.isEmpty(breadcrumb));

  return (
    <div
      className="breadcrumbs">
      <BrowseBreadcrumbs breadcrumbs={breadcrumbs} />
    </div>
  );
};

export default Breadcrumbs;

const formatProductTypeDescription = (permalink: string, ancestor_permalinks?: string[] = []) => {
  if (!ancestor_permalinks) return permalink;

  const ancestor_permalink = ancestor_permalinks.find(ancestor => _.startsWith(permalink, ancestor));
  return _.startCase(permalink.replace(new RegExp(`^${String(ancestor_permalink)}-`), ''));
};
