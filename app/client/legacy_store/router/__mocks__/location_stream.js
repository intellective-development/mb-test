// @flow

import Rx from 'rxjs';

export default Rx.Observable.of({
  page_type: 'product_list',
  fragment: '/store/category/wine',
  params: {
    hierarchy_category: 'wine',
    base: 'hierarchy_category'
  },
  meta: {
    base_url_filter: {
      hierarchy_category: 'wine',
      base: 'hierarchy_category'
    }
  }
});
