// @flow

import * as React from 'react';
import _ from 'lodash';
import formatCurrency from 'shared/utils/format_currency';
import { variant_helpers } from 'store/business/variant';
import { product_grouping_helpers } from 'store/business/product_grouping';
import type { ProductGrouping } from 'store/business/product_grouping';
import connectProductScroller from 'store/views/compounds/ProductScroller/ConnectProductScroller';
import { makeComponentAbleToAdd } from 'product_browse/AddToCart'; // TODO this uses the old event system
import { addSplitDeliveryWarning } from 'product_browse/AddSplitDeliveryWarning'; // TODO this uses the old event system
import {
  ProductListItemImage,
  ProductListItemSupplier,
  ProductListItemPropertyTag,
  ProductListItemPropertyName,
  ProductListItemPropertyVolume,
  ProductListItemPropertyPrice
} from 'store/views/scenes/ProductList/List/ProductListItemProperties';
import {
  CartPlacementTransitioner,
  SmallAddToCartButton
} from 'cart/cart_shared';
import SelectableList from 'cart/selectable_list';
import { MBLayout } from '../store/views/elements';

const VISIBLE_PRODUCT_COUNT = 3;

type AddonPlacementProps = {
  title?: string,
  content_url?: string,
  action_url?: string,
  internal_name?: string,
  // From HOC
  product_groupings: Array<ProductGrouping>,
  loadProductGroupings: () => {}
}

const AddonPlacement = ({ product_groupings, suppliers, cart_items, title }: AddonPlacementProps) => {
  if (_.isEmpty(product_groupings)) return null;

  return (
    <MBLayout.StandardGrid>
      <h2 className="heading-row cart-placement__header--addons">{title || 'Perfect Party Add-ons'}</h2>
      <SelectableList
        items={product_groupings}
        display_count={VISIBLE_PRODUCT_COUNT}
        renderContainer={(content) => (
          <CartPlacementTransitioner className="grid-product__container--cart--featured">
            {content}
          </CartPlacementTransitioner>
        )}
        renderItem={(item, selectItem) => (
          <AddonItem
            onClick={selectItem}
            placement={{ content: product_groupings }}
            product_grouping={item}
            variant={variant_helpers.defaultVariant(item.variants)}
            supplier={_.get(suppliers, variant_helpers.defaultVariant(item.variants).supplier_id)}
            cart_items={cart_items}
            key={item.id}
            visibleProductCount={VISIBLE_PRODUCT_COUNT}
            target="cart_addon_placement"
            tracking_identifier="cart_addon_placement" />
        )} />
    </MBLayout.StandardGrid>
  );
};

const AddonItem = makeComponentAbleToAdd(addSplitDeliveryWarning(({ product_grouping, variant, onClick, addToCart, buttonLifecycleState, supplier }) => (
  <li className="grid-product grid-product--cart--featured" onClick={() => { addToCart().then(onClick).catch(() => { }); }}>
    <div className="grid-product__link--image">
      <ProductListItemImage
        src={product_grouping_helpers.getThumb(product_grouping, variant)}
        alt={product_grouping.name} />
    </div>
    <div className="grid-product__contents__subcontainer">
      <div className="grid-product__link--contents">
        <ProductListItemSupplier supplier={supplier} />
        <ProductListItemPropertyTag propVal={product_grouping_helpers.primaryTag(product_grouping)} />
        <ProductListItemPropertyName propVal={product_grouping.name} />
        <ProductListItemPropertyVolume propVal={variant.volume} shouldRender={!!variant.volume} />
        <ProductListItemPropertyPrice price={formatCurrency(variant.price)} originalPrice={formatCurrency(variant.original_price)} />
      </div>
      <AddToCartWithPrompt buttonLifecycleState={buttonLifecycleState} />
    </div>
  </li>
)));

type AddToCartWithPromptProps = {buttonLifecycleState: string};
export const AddToCartWithPrompt = ({buttonLifecycleState}: AddToCartWithPromptProps) => {
  const prompt_content = buttonLifecycleState === 'added' ? 'added' : 'add';
  return (
    <div className={`add-to-cart__wrapper add-to-cart__wrapper--${buttonLifecycleState}`}>
      <span className="add-to-cart__prompt heading-thin-smaller">{prompt_content}</span>
      <SmallAddToCartButton buttonLifecycleState={buttonLifecycleState} />
    </div>
  );
};

export default connectProductScroller(AddonPlacement);
