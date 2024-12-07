// @flow

import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';

import type { Filter } from 'store/business/filter';
import type { ProductGrouping } from 'store/business/product_grouping';
import { product_list_helpers } from 'store/business/product_list';
import type { ProductList } from 'store/business/product_list';
import { search_switch_actions, search_switch_helpers, search_switch_selectors } from 'store/business/search_switch';
import type { SearchSwitch } from 'store/business/search_switch';
// import { variant_helpers } from 'store/business/variant';

import SearchSwitcher, { LoadingSearchSwitcher } from './SearchSwitcher';
import { FacetBar } from './FacetBar/index';
import ProductListItemInternal from './List/ListItemInternal';
import { ListWrapper, injectPromotions } from './List/ListWrapper';
import UnavailableMessage from './UnavailableMessage';

type ProductListInternalProps = {
  product_list_id: string,
  product_list: ProductList,
  filter: Filter,

  // STP
  product_groupings: ProductGrouping[],
  search_switch: SearchSwitch,
  search_switch_is_fetching: boolean,

  // DTP
  fetchSearchSwitch: typeof search_switch_actions.fetchSearchSwitch
};

class ProductListInternal extends React.Component<ProductListInternalProps> {
  componentWillReceiveProps(next_props: ProductListInternalProps){
    const product_list_is_empty = next_props.product_list
      && product_list_helpers.isEmpty(next_props.product_list)
      && !product_list_helpers.isProductListFetching(next_props.product_list);

    if (product_list_is_empty && !next_props.search_switch && !next_props.search_switch_is_fetching){
      this.props.fetchSearchSwitch(next_props.product_list_id);
    }
  }

  getVariantSubgroups = (variants/*, sort*/) => {
    return Object.entries({'': variants});
    /*if (product_list_helpers.isSortType(sort, 'price')){
      return Object.entries({'': variants});
    } else {
      return Object.entries(variant_helpers.variantSubgroups(variants));
    }*/
  }

  renderListItems(){
    const { filter, product_groupings, product_list } = this.props;
    const sort = product_list_helpers.getSortForList(product_list);
    const promotions = product_list_helpers.getPromotionsForList(product_list);

    const items = _.compact(_.flatten(product_groupings.map(product_grouping =>
      this.getVariantSubgroups(product_grouping.variants, sort).map(([subgroup_id, variants]) => (
        <ProductListItemInternal
          filter={filter}
          product_grouping={product_grouping}
          variants={variants}
          key={`product_${product_grouping.id}_${subgroup_id}`} />
      ))
    )
    ));

    return injectPromotions(promotions, items);
  }

  renderContent(){
    const { product_list, product_list_id, search_switch, search_switch_is_fetching, filter } = this.props;

    const list_empty = product_list_helpers.isEmpty(product_list);
    const list_fetching = product_list_helpers.isProductListFetching(product_list);

    // const list_is_loading = !product_list || !filter || (list_fetching && list_empty);
    const search_switch_is_present = search_switch && !search_switch_helpers.isEmpty(search_switch);

    if (search_switch_is_fetching){
      return <LoadingSearchSwitcher />;
    } else if (search_switch_is_present){
      return <SearchSwitcher search_switch={search_switch} />;
    } else {
      return (<ListWrapper filter={filter} product_list={product_list} product_list_id={product_list_id}>
        {list_empty && !list_fetching ? <UnavailableMessage filter={filter} /> : this.renderListItems()}
      </ListWrapper>);
    }
  }

  render(){
    const { product_list, product_list_id, filter } = this.props;

    return (
      <React.Fragment>
        <FacetBar
          product_list_id={product_list_id}
          product_list={product_list}
          filter={filter} />
        {this.renderContent()}
      </React.Fragment>
    );
  }
}

const ProductListInternalSTP = () => {
  const findSearchSwitch = Ent.find('search_switch');
  const findProductGroupings = Ent.query(Ent.find('product_grouping'), Ent.join('variants'));

  return (state, {product_list, product_list_id}) => ({
    product_groupings: findProductGroupings(state, product_list_helpers.getProductIdsForList(product_list)),
    search_switch: findSearchSwitch(state, product_list_id),
    search_switch_is_fetching: search_switch_selectors.isSearchSwitchFetching(state, product_list_id)
  });
};

const ProductListInternalDTP = {
  fetchSearchSwitch: search_switch_actions.fetchSearchSwitch
};

const ProductListInternalContainer = connect(ProductListInternalSTP, ProductListInternalDTP)(ProductListInternal);

export default ProductListInternalContainer;
