// @flow

import React from 'react';

import type { ContentModule } from 'store/business/content_module';
import BrandDescription from './BrandDescription';
import ColumnLayout from './ColumnLayout';
import MBCarousel from './Carousel';
import ImageGrid from './ImageGrid';
import LinkList from './LinkList';
import ProductScroller from './ProductScroller';
import CocktailScroller from './CocktailScroller';
import PreviousOrders from './PreviousOrders';
import ProductVideo from './ProductVideo';
import ShippingRequiredNotification from './ShippingRequiredNotification';
import TextBlock from './TextBlock';
import TextCarousel from './TextCarousel';

const content_modules = {
  brand_description: BrandDescription,
  column_layout: ColumnLayout,
  carousel: MBCarousel,
  text_carousel: TextCarousel,
  image_grid: ImageGrid,
  link_list: LinkList,
  product_scroller: ProductScroller,
  cocktail_scroller: CocktailScroller,
  product_video: ProductVideo,
  previous_orders: PreviousOrders,
  shipping_required_notification: ShippingRequiredNotification,
  text_block: TextBlock
};

export type ContentModuleProps = {
  content_layout_id: string,
  content_module: ContentModule
};

const GenericContentModule = ({ content_layout_id, content_module }: ContentModuleProps) => {
  const Module = content_modules[content_module.module_type];

  if (!Module) return null;

  return <Module content_layout_id={content_layout_id} content_module={content_module} />;
};

export {
  GenericContentModule as default,
  content_modules
};
