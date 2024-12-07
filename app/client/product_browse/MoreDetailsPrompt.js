import * as React from 'react';
import { useDispatch } from 'react-redux';

import { MBLink, MBTouchable } from 'store/views/elements';

import { ShowAddToCartModal } from './product_browse.dux';

const ButtonLabel = ({ text }) => <span className="grid-product__button-label">{text}</span>;

const MoreDetails = ({ href, label, product_grouping, current_variant }) => {
  const dispatch = useDispatch();

  return (
    <div>
      {label ? <ButtonLabel text={label} /> : null}
      {href ? (
        <MBLink.View className="button small expand" href={href} data-category="product placement" native_behavior>
          See Details
        </MBLink.View>
      ) : (
        <MBTouchable
          className="button small expand add-to-cart actions__add-to-cart"
          onClick={() => {
            const variant = current_variant || product_grouping.variants[0];
            dispatch(ShowAddToCartModal({ modalOpen: true, product_grouping, variant }));
          }}>
          Add to Cart
        </MBTouchable>
      )}
    </div>
  );
};

export default MoreDetails;
