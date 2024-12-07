import React from 'react';
import { MBLink } from '../../../elements';

export default ({ product_grouping }) => (
  <div className="panel__wrapper">
    <div className="panel--unavailable">
      <p className="panel--pdp--message">This product is not available at your address.</p>
      <MBLink.View
        href={`/store/category/${product_grouping.hierarchy_category.permalink}`}
        className="link-generic button">
        See More
      </MBLink.View>
    </div>
  </div>
);
