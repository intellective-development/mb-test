import PropTypes from 'prop-types';
import * as React from 'react';
import {
  BrandSelect,
  ProductTypeSelect,
  SupplierSelect,
  StockFilterSelect,
  StateFilterSelect,
  HasImageToggle,
  OrderBySelect,
  PreSaleLTOFilterSelect
} from 'admin/admin_select';
import SimpleInput from './utils/simple_input';

// TODO: BC: move this height calc to admin select with chars per
// line and height increase as props, also strip out of invoice
// recipient select bootstraping
const CHARS_PER_LINE = 20;
const HEIGHT_INCREASE_ON_WRAP = 8;
// options become larger as text wraps
const CALCULATE_OPTION_HEIGHT = (obj) => {
  let height = 24;
  const text = obj.option.name || obj.option.label; // 'name' for API options, 'label' for static options
  height += (Math.floor(text.length / CHARS_PER_LINE) * HEIGHT_INCREASE_ON_WRAP);
  return height;
};

const CatalogSideBar = ({
  initialBrandIds = [],
  initialProductTypeIds = [],
  initialSupplierIds = [],
  initialStateFilters = [],
  initialStockFilter = [],
  initialPreSaleLTOFilter = [],
  initialImageToggleOptions = [],
  initialOrderByOption = [],
  initialProductIdFilter = '',
  initialProductGroupingIdFilter = '',
  initialSkuFilter = '',
  initialMerchantSkuFilter = '',
  catalogSideBarVersion = 'v1'
}) => (
  <div>
    <OrderBySelect
      initialValues={initialOrderByOption}
      name="sort"
      placeholder="Default"
      optionHeight={CALCULATE_OPTION_HEIGHT} />
    <BrandSelect
      initialValueIds={initialBrandIds}
      name="brand_ids[]"
      placeholder="All"
      optionHeight={CALCULATE_OPTION_HEIGHT}
      multi />
    <ProductTypeSelect
      initialValueIds={initialProductTypeIds}
      name="product_type_ids[]"
      placeholder="All"
      optionHeight={CALCULATE_OPTION_HEIGHT}
      multi />
    <SupplierSelect
      initialValueIds={initialSupplierIds}
      name="supplier_ids[]"
      placeholder="All"
      optionHeight={CALCULATE_OPTION_HEIGHT}
      multi />
    <StateFilterSelect
      initialValues={initialStateFilters}
      name="state_filters[]"
      placeholder="All"
      optionHeight={CALCULATE_OPTION_HEIGHT}
      multi />
    <StockFilterSelect
      initialValues={initialStockFilter}
      name="stock_filter"
      placeholder="All"
      optionHeight={CALCULATE_OPTION_HEIGHT} />
    <HasImageToggle
      initialValues={initialImageToggleOptions}
      name="has_image"
      placeholder="Select"
      optionHeight={CALCULATE_OPTION_HEIGHT} />
    <PreSaleLTOFilterSelect
      initialValues={initialPreSaleLTOFilter}
      name="pre_sale_lto_filter"
      placeholder="All"
      optionHeight={CALCULATE_OPTION_HEIGHT} />
    <SimpleInput
      initialValue={initialSkuFilter}
      name="sku"
      placeholder="Any"
      label="SKU"
      type="text" />
    {catalogSideBarVersion === 'v2' && (
      <React.Fragment>
        <SimpleInput
          initialValue={initialMerchantSkuFilter}
          name="merchant_sku"
          placeholder="Any"
          label="Merchant SKU"
          type="text" />
        <SimpleInput
          initialValue={initialProductIdFilter}
          name="product_id"
          placeholder="Any"
          label="Product ID"
          type="text" />
        <SimpleInput
          initialValue={initialProductGroupingIdFilter}
          name="product_grouping_id"
          placeholder="Any"
          label="Product Grouping ID"
          type="text" />
      </React.Fragment>
    )}
  </div>
);

CatalogSideBar.propTypes = {
  initialBrandIds: PropTypes.array,
  initialProductTypeIds: PropTypes.array,
  initialSupplierIds: PropTypes.array,
  initialStateFilters: PropTypes.array,
  initialStockFilter: PropTypes.array,
  initialPreSaleLTOFilter: PropTypes.array,
  initialImageToggleOptions: PropTypes.array,
  initialOrderByOption: PropTypes.array,
  initialSkuFilter: PropTypes.string,
  initialProductIdFilter: PropTypes.string,
  initialProductGroupingIdFilter: PropTypes.string,
  initialMerchantSkuFilter: PropTypes.string,
  catalogSideBarVersion: PropTypes.string
};

export default CatalogSideBar;
