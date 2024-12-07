import * as React from 'react';
import AsyncSelect from 'admin/select_components/async_select';
import StaticSelect from 'admin/select_components/static_select';
import {
  fetchBrands,
  fetchCocktails,
  fetchProducts,
  fetchProductTypes,
  fetchProductGroupings,
  fetchSuppliers
} from 'admin/admin_api';

export const BrandSelect = ({name = 'brand', type = 'Brand', label = 'Brand', ...rest_props}) => (
  <AsyncSelect
    loadOptions={fetchBrands}
    name={name}
    type={type}
    label={label}
    {...rest_props} />
);

export const ProductSelect = ({name = 'product', type = 'Product', label = 'Product', ...rest_props}) => (
  <AsyncSelect
    loadOptions={fetchProducts}
    name={name}
    type={type}
    label={label}
    {...rest_props} />
);

export const ProductTypeSelect = ({name = 'product_type', type = 'ProductType', label = 'Product Type', ...rest_props}) => (
  <AsyncSelect
    loadOptions={fetchProductTypes}
    name={name}
    type={type}
    label={label}
    {...rest_props} />
);

export const CocktailSelect = ({name = 'cocktail', type = 'Cocktail', label = '', ...rest_props}) => (
  <AsyncSelect
    loadOptions={fetchCocktails}
    name={name}
    type={type}
    label={label}
    {...rest_props} />
);

export const ProductGroupingSelect = ({name = 'product_grouping', type = 'ProductGrouping', label = 'Product Grouping', ...rest_props}) => (
  <AsyncSelect
    loadOptions={fetchProductGroupings}
    name={name}
    type={type}
    label={label}
    {...rest_props} />
);

export const SupplierSelect = ({name = 'supplier', type = 'Supplier', label = 'Supplier', ...rest_props}) => (
  <AsyncSelect
    loadOptions={fetchSuppliers}
    name={name}
    type={type}
    label={label}
    {...rest_props} />
);

const STOCK_FILTER_OPTIONS = [
  {label: 'In-Stock', value: 'in'},
  {label: 'Out-of-Stock', value: 'out'}
];
export const StockFilterSelect = ({name = 'stock_filter', label = 'Stock Filter', ...rest_props}) => (
  <StaticSelect
    options={STOCK_FILTER_OPTIONS}
    name={name}
    label={label}
    {...rest_props} />
);

const HAS_IMAGE_OPTIONS = [
  {label: 'Yes', value: 'true'},
  {label: 'No', value: 'false'}
];
export const HasImageToggle = ({name = 'has_image', label = 'Has Image', ...rest_props}) => (
  <StaticSelect
    options={HAS_IMAGE_OPTIONS}
    name={name}
    label={label}
    {...rest_props} />
);

const STATE_FILTER_OPTIONS = [
  {label: 'Active', value: 'active'},
  {label: 'Inactive', value: 'inactive'},
  {label: 'Pending', value: 'pending'},
  {label: 'Flagged', value: 'flagged'}
];
export const StateFilterSelect = ({name = 'state_filters[]', label = 'State Filter', ...rest_props}) => (
  <StaticSelect
    options={STATE_FILTER_OPTIONS}
    name={name}
    label={label}
    {...rest_props} />
);

const ORDER_BY_OPTIONS = [
  {label: 'Name', value: 'name_downcase'},
  {label: 'Variants Count', value: 'variant_count'}
];
export const OrderBySelect = ({name = 'sort', label = 'Order By', ...rest_props}) => (
  <StaticSelect
    options={ORDER_BY_OPTIONS}
    name={name}
    label={label}
    {...rest_props} />
);

const BUNDLE_TYPE_OPTIONS = [
  {label: 'Product Grouping', value: 'ProductSizeGrouping'},
  {label: 'Product Type', value: 'ProductType'},
  {label: 'Brand', value: 'Brand'}
];
export const BundleTypeSelect = ({name = 'bundle_type', label = 'Bundle Type', ...rest_props}) => (
  <StaticSelect
    options={BUNDLE_TYPE_OPTIONS}
    name={name}
    label={label}
    {...rest_props} />
);

const PRE_SALE_LTO_FILTER_OPTIONS = [
  { label: 'Pre Sale', value: 'has_active_pre_sale' },
  { label: 'Limited Time Offer', value: 'limited_time_offer' }
];
export const PreSaleLTOFilterSelect = ({ name = 'pre_sale_lto_filter', label = 'Pre Sale LTO Filter', ...rest_props }) => (
  <StaticSelect
    options={PRE_SALE_LTO_FILTER_OPTIONS}
    name={name}
    label={label}
    {...rest_props} />
);
