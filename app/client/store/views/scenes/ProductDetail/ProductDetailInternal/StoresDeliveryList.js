/* @flow */

import {
  compact,
  filter,
  find,
  flatMap,
  get,
  head,
  includes,
  intersection,
  isEmpty,
  isNil,
  map,
  some,
  sortBy,
  uniq
} from 'lodash';
import React, { Component } from 'react';
import { connect } from 'react-redux';

import * as Ent from '@minibar/store-business/src/utils/ent';

import { hasShopRunnerToken } from 'shared/utils/shop_runner';

import { cart_item_selectors } from 'store/business/cart_item';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { supplier_selectors } from 'store/business/supplier';
import { variant_helpers } from 'store/business/variant';

import { MBTab, MBTablist, MBTabs } from '../../../elements/MBTabs';

import {
  UnavailablePanel
} from '../ProductDetailElements';

import ContainerList from './ContainersList';
import SizeSelector from './SizeSelector';
import VariantItem from './VariantItem';
import ShippingTypeSelector from './ShippingTypeSelector';

const getContainers = (...variants) =>
  uniq(compact(map(variants, 'container_type')));

const getCriteria = ({ container, selected, volume }) => {
  switch (true){
    case !isNil(container):
      return {
        container_type: container
      };
    case !isNil(volume):
      return {
        container_type: get(selected, 'container_type'),
        volume: volume
      };
    default:
      return {
        container_type: get(selected, 'container_type'),
        volume: get(selected, 'volume')
      };
  }
};

const getSelections = (props, state) => ({ container, selection, shipping, volume }) => {
  let delivery;
  let selected;
  let variants;

  switch (true){
    case !isNil(shipping):
      selected = head(getVariants(props)(getCriteria({ selected: get(state, 'selected') }), shipping));
      delivery = shipping;
      break;
    case !isNil(volume):
      variants = getVariants(props)(getCriteria({ selected: get(state, 'selected'), volume }));
      delivery = head(getShippingTypes(...getSuppliers(props)(variants)));
      selected = head(getVariants(props)(getCriteria({ selected: get(state, 'selected'), volume }), delivery));
      break;
    case !isNil(container):
      variants = getVariants(props)(getCriteria({ selected: get(state, 'selected'), container }));
      delivery = head(getShippingTypes(...getSuppliers(props)(variants)));
      selected = head(getVariants(props)(getCriteria({ container }), delivery));
      break;
    case !isNil(selection):
      selected = selection;
      delivery = head(get(selected, 'delivery.methods'));
      break;
    default:
      break;
  }

  return {
    container: get(selected, 'container_type'),
    selected,
    shipping: delivery,
    volume: get(selected, 'volume')
  };
};

const getShippingTypes = (...suppliers) =>
  intersection(
    ['on_demand', 'shipped', 'vineyard_select'],
    flatMap(
      suppliers,
      supplier => (
        supplier.type === 'Vineyard Select'
          ? ['vineyard_select']
          : map(supplier.deliveryMethods, ({ type }) => type)
      )
    )
  );

const getSupplier = ({ cart_items, suppliers }) => id => {
  const supplier = find(suppliers, { id });
  if (!supplier) return;
  const isClosed = delivery_method_helpers.isClosed(head(get(supplier, 'deliveryMethods')));
  const isInCart = !includes(flatMap(cart_items, 'supplier_id'), id);
  const shippingTypes = getShippingTypes(supplier);

  return {
    ...supplier,
    isClosed,
    isInCart,
    shippingTypes
  };
};

const getSuppliers = ({ suppliers }) => variants =>
  uniq(compact(flatMap(
    uniq(compact(map(variants, 'supplier_id'))),
    id => filter(suppliers, { id })
  )));

const getVariant = ({ cart_items, productGrouping, suppliers }) => variant => {
  const supplier = getSupplier({ cart_items, suppliers })(get(variant, 'supplier_id'));
  if (!supplier) return;

  return {
    ...variant,
    productGrouping,
    delivery: {
      methods: get(supplier, 'shippingTypes')
    },
    supplier
  };
};

const getVariants = ({ cart_items, suppliers, variants, ...productGrouping }) => (criteria, shipping) => {
  let results = compact(map(
    filter(variants, criteria),
    getVariant({ cart_items, productGrouping, suppliers })
  ));

  if (shipping && some(results, ({ delivery }) => includes(delivery.methods, shipping))){
    results = filter(
      results,
      ({ delivery }) => includes(delivery.methods, shipping)
    );
  }

  return sortBy(
    results,
    ['supplier.isInCart', 'supplier.isClosed', 'price', 'supplier.distance']
  );
};

const getVolumes = (...variants) =>
  uniq(compact(map(sortBy(
    variants,
    [
      ({ short_volume }) => {
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
      }
    ]), 'volume')));

/*:
  type SupplierListProps = {
    productGrouping: Object,
    variants: Array
  }
*/

class SupplierList extends Component /*:: <SupplierListProps> */ {
  constructor(props){
    super(props);

    const criteria = getCriteria({
      selected: variant_helpers.getVariant(props.variants, props.default_variant_permalink) || variant_helpers.defaultVariant(props.variants)
    });
    const shipping = head(getShippingTypes(...getSuppliers(props)(props.variants)));
    const variants = getVariants(props)(criteria, shipping);
    const selected = head(variants);

    this.state = {
      container: get(selected, 'container_type'),
      more: false,
      selected,
      shipping,
      volume: get(selected, 'volume')
    };
  }

  setContainer = (container) => this.setState(state => getSelections(this.props, state)({ container }));
  setSelected = (selection) => this.setState(state => getSelections(this.props, state)({ selection }));
  setShipping = (shipping) => this.setState(state => getSelections(this.props, state)({ shipping }));
  setVolume = (volume) => this.setState(state => getSelections(this.props, state)({ volume }));

  toggleMore = () =>
    this.setState(state => ({ more: !state.more }));

  render(){
    const { container, more, selected, shipping, volume } = this.state;

    const containers = getContainers(...this.props.variants);
    const volumes = getVolumes(...getVariants(this.props)(getCriteria({ container })));
    const shippingTypes = getShippingTypes(...getSuppliers(this.props)(getVariants(this.props)(getCriteria({ selected }))));
    const delivery = includes(shippingTypes, shipping)
      ? shipping
      : head(get(selected, 'delivery.methods'));
    const variants = getVariants(this.props)(getCriteria({ selected }), delivery);

    const show = this.props.show || 3;

    if (isEmpty(variants)){
      return (<UnavailablePanel permalink={this.props.hierarchy_category.permalink} />);
    }
    if (this.props.supplierListCallback){
      this.props.supplierListCallback(variants.map(variant => variant.supplier));
    }

    return (
      <div className="PDP_Internal">
        <div>
          <ContainerList
            containers={containers}
            onSelect={this.setContainer}
            selected={container} />
          <SizeSelector
            onSelect={this.setVolume}
            selected={volume}
            volumes={volumes} />
        </div>

        <div>
          <ShippingTypeSelector
            key={volume}
            onSelect={this.setShipping}
            selected={delivery}
            shippingTypes={shippingTypes} />
          <MBTabs
            key={get(selected, 'id')}
            selected={`id${get(selected, 'id')}`}>
            <MBTablist className="storelist">
              {variants.map((variant, i) => {
                if (more || i < show){
                  return (
                    <MBTab
                      className="storetab"
                      key={variant.id}
                      label={`id${variant.id}`}>
                      <VariantItem
                        cart_items={this.props.cart_items}
                        className="store"
                        key={variant.id}
                        productGrouping={variant.productGrouping}
                        selected={selected}
                        setSelected={this.setVariant}
                        shipping={shipping}
                        addToCardHandler={this.props.addToCardHandler}
                        variant={variant} />
                    </MBTab>
                  );
                }
                return (<React.Fragment key={variant.id} />);
              })}
              <div className="storelist_foot">
                { variants.length > show && show > 1
                  ? (<button
                    className="store_toggle"
                    onClick={this.toggleMore}>
                    <span>Show { more ? 'fewer' : 'more' } stores</span>
                    <span>{ more ? '–' : '+' }</span>
                  </button>)
                  : null
                }
              </div>
            </MBTablist>
          </MBTabs>
          <ShopRunnerPanel />
        </div>
      </div>
    );
  }
}

const ShopRunnerPanel = () => {
  const hasShopRunnerTokenClass = hasShopRunnerToken() ? 'with-token' : '';

  return <div className={`cart-shoprunner shop_runner ${hasShopRunnerTokenClass}`} name="sr_headerDiv" />;
};

//TODO: move to store-business with reselect
const getCartItemsFromState = Ent.query(
  Ent.find('cart_item'),
  Ent.join('variant'),
  Ent.join('product_grouping')
);

const getSupplierFromState = state => supplier_id => {
  const supplier = state.supplier.by_id[supplier_id] || {};

  supplier.deliveryMethods = compact(map(
    supplier.delivery_methods,
    id => state.delivery_method.by_id[id]
  ));

  return supplier;
};

const SupplierListSTP = state => ({
  cart_items: getCartItemsFromState(
    state, cart_item_selectors.getAllCartItemIds(state)
  ),
  suppliers: map(
    supplier_selectors.currentSupplierIds(state),
    getSupplierFromState(state)
  )
});

export default connect(SupplierListSTP)(SupplierList);
