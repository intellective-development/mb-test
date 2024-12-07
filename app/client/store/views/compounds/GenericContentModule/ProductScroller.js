// @flow

import * as React from 'react';
import ProductScroller from '../ProductScroller';
import type { ContentModuleProps } from './index';
import connectProductScroller from '../ProductScroller/ConnectProductScroller';

const ConnectedProductScroller = connectProductScroller(ProductScroller);
const ProductScrollerModule = ({ content_module }: ContentModuleProps) => (
  <ConnectedProductScroller
    content_module_id={content_module.id}
    product_ids={content_module.products}
    internal_name={content_module.internal_name}
    {...content_module.config} />
);


export default ProductScrollerModule;
