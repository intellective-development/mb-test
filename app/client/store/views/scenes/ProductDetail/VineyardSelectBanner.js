// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';

type OwnProps = {
  supplier_id: number
};

type StateProps = {
  is_vineyard_select: boolean
}

const VineyardSelectBanner = ({ is_vineyard_select }: OwnProps & StateProps) => {
  if (!is_vineyard_select) return null;

  return (
    <picture>
      <source
        media="(min-width: 768px)"
        alt="Vineyard Select - Shipments arrive in 3-5 days"
        srcSet="/assets/components/scenes/product_detail/VS_webBanner.png,
      /assets/components/scenes/product_detail/VS_webBanner@2x.png 2x" />
      <source
        alt="Vineyard Select - Shipments arrive in 3-5 days"
        srcSet="/assets/components/scenes/product_detail/VS_mobileBanner.png,
      /assets/components/scenes/product_detail/VS_mobileBanner@2x.png 2x,
                /assets/components/scenes/product_detail/VS_mobileBanner@3x.png 3x" />
      <img
        className="product-detail__vineyard-select"
        src="/assets/components/scenes/product_detail/VS_mobileBanner.png"
        alt="Vineyard Select - Shipments arrive in 3-5 days" />
    </picture>
  );
};

const VineyardSelectBannerSTP = () => {
  const findSupplier = Ent.find('supplier');

  return (state, { supplier_id }: OwnProps): StateProps => {
    const supplier = findSupplier(state, supplier_id);
    const is_vineyard_select = supplier ? supplier.type === 'Vineyard Select' : false;
    return { is_vineyard_select };
  };
};

export default connect(VineyardSelectBannerSTP)(VineyardSelectBanner);
