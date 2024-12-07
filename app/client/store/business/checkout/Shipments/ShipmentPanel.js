// @flow

import { css } from '@amory/style/umd/style';
import { map, isNumber } from 'lodash';
import React, { Fragment } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Truncate from 'react-dotdotdot';
import { product_grouping_helpers } from 'store/business/product_grouping';
import { toFixed } from 'client/modules/utils';
import { selectVariantById } from 'client/modules/variant/variant.dux';
import { selectSupplierById } from 'client/modules/supplier/supplier.dux';
import { selectProductGroupingById } from 'client/modules/productGrouping/productGrouping.dux';
import { updateCartItemQuantity, removeCartItem } from 'client/modules/cartItem/cartItem.dux';
import icon from '../shared/MBIcon/MBIcon';
import ProductIcon from '../shared/MBIcon/ProductIcon';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import Hr from '../shared/Hr';
import Row from '../shared/Row';
import styles from '../Checkout.css.json';


//import ShippingSupplierSummary from './ShippingSupplierSummary';

/*::
type ShipmentPanelProps = {shipment: Object, supplierId: String};
*/
const Item = ({
  product_grouping,
  quantity,
  variant,
  id
}) => {
  const dispatch = useDispatch();
  const removeItem = () => dispatch(removeCartItem(id));
  const setQuantity = qty => {
    if (isNumber(qty) && qty > 0){
      dispatch(updateCartItemQuantity(id, qty, quantity));
    } else {
      removeItem();
    }
  };
  const { name, ...productGroupingProps } = useSelector(selectProductGroupingById)(product_grouping) || {};
  const { price, volume, in_stock, ...variantProps } = useSelector(selectVariantById)(variant) || {};
  const thumb_url = product_grouping_helpers.getThumb(productGroupingProps, variantProps);
  const maxQty = Math.min(in_stock, quantity + 29) + 1;
  const qtyArray = [...Array(maxQty).keys()];
  qtyArray.shift();

  return (
    <Row style={{ margin: '15px 5px' }}>
      <div
        className={css([
          styles.summarythumb,
          {
            minWidth: 60
          }
        ])}>
        {thumb_url
          ? (
            <img
              alt={`${name} ${volume}`}
              className={css(styles.summarythumb)}
              src={thumb_url} />
          )
          : (
            <ProductIcon
              className={css(styles.summarythumb)} />
          )
        }
      </div>
      <div className={css(styles.summaryproduct)}>
        <div className={css(styles.summaryname)}>
          <Truncate clamp={2}>{name}</Truncate>
        </div>
        <div>
          {volume}
        </div>
      </div>
      <div className={css(styles.summary)}>
        <span>$ {toFixed(price, 2)}</span>
      </div>
      <div className={css(styles.summaryqty)}>
        <select
          className={css({ marginTop: 8 })}
          onChange={e => setQuantity(parseInt(e.target.value))}>
          {map(qtyArray, i => (<option selected={quantity === i}>{i}</option>))}
        </select>
        <button
          className={css([
            unstyle.button,
            styles.remove
          ])}
          onClick={removeItem}
          type="button">
          Remove
        </button>
      </div>
      <div
        className={css(styles.summary)}>
        <span>$ {toFixed(price * quantity, 2)}</span>
      </div>
    </Row>
  );
};

const ShipmentPanel = ({
  shipment,
  supplierId
} /*: ShipmentPanelProps */) => {
  // TODO: exclude bartender
  const supplier = useSelector(selectSupplierById)(supplierId) || {};

  return (
    <Fragment>
      <Hr />
      <Row>
        <div
          className={css([
            icon({
              color: 'rgba(0,0,0,.6)',
              name: 'storefront'
            }),
            styles.summarystore
          ])}>
          <div className={css(styles.suppliername)}>
            {supplier.name}
          </div>
        </div>
      </Row>
      {shipment.map(item => <Item key={item.id} {...item} />)}
      <Hr />
    </Fragment>
  );
};

export default ShipmentPanel;
