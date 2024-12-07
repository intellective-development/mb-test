// @flow

import 'shared/polyfills';
import * as React from 'react';
import _ from 'lodash';
import ReactDOM from 'react-dom';

import apiAuthenticate from './shared/web_authentication';
import {
  BrandSelect,
  ProductGroupingSelect,
  ProductTypeSelect,
  ProductSelect,
  SupplierSelect,
  CocktailSelect,
  HasImageToggle,
  OrderBySelect
} from './admin/admin_select';
import SellableSelect from './admin/sellable_select';
import UserSelect from './admin/memberships/user_select';
import CatalogSideBar from './admin/catalog_side_bar';
import Cocktails from './admin/cocktails';
import JsonEditor from './admin/json_editor';
import DeliveryZoneEditor from './admin/delivery_zone_editor';
import DeliveryZoneCoverages from './admin/delivery_zone_coverages';
import AdditionalUpcHandler from './admin/additional_upc_handler';
import FraudulentAccounts from './admin/fraudulent_accounts';
import BrandDistributors from './admin/brand_distributors';
import BundleSource from './admin/bundle_source';
import BundleItems from './admin/bundle_items';
import UpdateEngravingOptions from './admin/update_engraving_options';
import SupplierEmailsEdit from './admin/supplier_emails_edit';
import PromotedFacetFiltersBrand from './admin/promoted_facet_filters_brand';

// this mapping connects the string representation
// of a component to its imported variable name for declaration
const component_map = {
  Cocktails,
  BrandSelect,
  CatalogSideBar,
  DeliveryZoneCoverages,
  DeliveryZoneEditor,
  AdditionalUpcHandler,
  HasImageToggle,
  JsonEditor,
  CocktailSelect,
  ProductGroupingSelect,
  ProductTypeSelect,
  ProductSelect,
  SellableSelect,
  SupplierSelect,
  OrderBySelect,
  FraudulentAccounts,
  BrandDistributors,
  BundleSource,
  BundleItems,
  UpdateEngravingOptions,
  SupplierEmailsEdit,
  PromotedFacetFiltersBrand,
  UserSelect
};

apiAuthenticate();

const initComponents = (element_component_mapping) => {
  _.forEach(element_component_mapping, (element) => {
    const container = document.getElementById(element.selector);
    if (container){
      ReactDOM.render(React.createElement(component_map[element.component], element.options), container);
    }
  });
};

const destroyComponents = (element_component_mapping) => {
  _.forEach(element_component_mapping, (element) => {
    const container = document.getElementById(element.selector);
    if (container){
      ReactDOM.unmountComponentAtNode(container);
    }
  });
};

// define in global scope
window.initComponents = initComponents;
window.destroyComponents = destroyComponents;
