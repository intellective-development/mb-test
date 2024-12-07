// @flow

import * as React from 'react';
import CocktailScroller from '../CocktailScroller';
import type { ContentModuleProps } from './index';
import connectCocktailScroller from '../CocktailScroller/ConnectCocktailScroller';

const ConnectedCocktailScroller = connectCocktailScroller(CocktailScroller);
const CocktailScrollerModule = ({ content_module }: ContentModuleProps) => (
  <ConnectedCocktailScroller
    content_module_id={content_module.id}
    product_ids={content_module.products}
    internal_name={content_module.internal_name}
    {...content_module.config} />
);


export default CocktailScrollerModule;
