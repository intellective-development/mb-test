// @flow
import type { ListLink } from 'store/business/content_module';

export const NAVIGATION_CATEGORY_DEFAULTS: ListLink[] = [
  {name: 'wine', internal_name: 'wine', action_url: '/store/category/wine'},
  {name: 'liquor', internal_name: 'liquor', action_url: '/store/category/liquor'},
  {name: 'beer', internal_name: 'beer', action_url: '/store/category/beer'},
  {name: 'mixers', internal_name: 'mixers', action_url: '/store/category/mixers'},
  {name: 'gifts', internal_name: 'gifts', action_url: '/store/promos/gift-guide'}
];
