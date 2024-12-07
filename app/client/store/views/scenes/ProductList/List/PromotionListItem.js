// @flow

import * as React from 'react';
import classNames from 'classnames';
import { product_list_constants } from 'store/business/product_list';
import WithPromotionTracking from '../../../compounds/WithPromotionTracking';
import { MBLink } from '../../../elements';

type PromotionListItemProps = {
  promotion: product_list_constants.Promotion
};

const PromotionListItem = ({ promotion }: PromotionListItemProps) => {
  const element_classes = classNames('grid-product grid-product--browse--promotion', {
    'grid-product--browse--promotion--linkable': promotion.url
  });

  return (
    <WithPromotionTracking render={({ trackPromotion }) => (
      <li className={element_classes}>
        <MBLink.View href={promotion.url} native_behavior disabled={!promotion.url} beforeNavigate={() => trackPromotion(promotion.name, 'plp')}>
          <img src={promotion.image_path} alt={promotion.name} />
        </MBLink.View>
      </li>
    )} />
  );
};

export default PromotionListItem;
