import { css } from '@amory/style/umd/style';
import { isEmpty, reduce, values } from 'lodash';
import React, { useRef, useState } from 'react';
import { useSelector } from 'react-redux';
import { selectShipmentsGrouped } from 'modules/cartItem/cartItem.dux';
import {
  selectCheckoutOrder, selectOrderData
} from 'modules/checkout/checkout.selectors';
import { CreateOrderProcedure } from 'modules/checkout/checkout.procedures';
import formatCurrency from 'shared/utils/format_currency';
import { hasShopRunnerToken } from 'shared/utils/shop_runner';
import deliveryCost from './deliveryCost';
import TipEdit from '../Totals/TipEdit';

function formatPriceFree(price){
  if (price == null){
    return '$';
  } else if (parseFloat(price) === 0){
    return 'FREE';
  } else {
    return `$${parseFloat(price).toFixed(2)}`;
  }
}

export const SummaryTable = () => {
  const inputEl = useRef(null);
  const order = useSelector(selectCheckoutOrder) || {};
  const orderData = useSelector(selectOrderData);
  const [tipEditing, setTipEditing] = useState(false);
  const shipments = useSelector(selectShipmentsGrouped);

  if (isEmpty(order.amounts)){
    return null;
  }

  const {
    // coupon,
    discounts,
    shipping,
    subtotal,
    tax,
    tip,
    total
  } = order.amounts || {};

  const { coupons, deals } = discounts || {};

  const itemQty = reduce(values(shipments), (qty, shipment) => qty + shipment.reduce((subqty, { quantity }) => subqty + quantity, 0), 0);

  const updateTip = () => CreateOrderProcedure({ ...orderData, tip: parseFloat(inputEl.current.value) })
    .then(() => { setTipEditing(false); });

  return (
    <table className="table-summary">
      <tbody>
        <tr>
          <th>SUBTOTAL ({itemQty} ITEM{itemQty !== 1 ? 'S' : ''})</th>
          <td>{formatCurrency(subtotal)}</td>
        </tr>
        <tr>
          <th>TAX</th>
          <td>{formatCurrency(tax)}</td>
        </tr>
        <tr>
          <th>DELIVERY</th>
          <td>{deliveryCost(hasShopRunnerToken(), formatPriceFree(shipping))}</td>
        </tr>
        { tip !== undefined && <tr>
          <th style={{ verticalAlign: 'middle' }}>TIP</th>
          <td className={css({ padding: 0 })}>
            <TipEdit
              inputEl={inputEl}
              setTipEditing={setTipEditing}
              tip={tip}
              tipEditing={tipEditing}
              updateTip={updateTip} />
          </td>
        </tr>}
        { !!coupons && <tr>
          <th>PROMO CODE</th>
          <td style={{ color: '#12781e' }}>
            - {formatCurrency(coupons)}
          </td>
        </tr> }
        { !!deals && <tr>
          <th>
            SPECIAL OFFER
            {order.qualified_deals.map(deal => (
              <div key={deal} className={css({ marginTop: '0.5em', color: '#757575', fontSize: 'smaller' }, 'summary-deal')}>{deal}</div>
            ))}
          </th>
          <td style={{ color: '#12781e' }}>- {formatCurrency(deals)}</td>
        </tr> }
      </tbody>
      <tfoot>
        <tr>
          <th>TOTAL</th>
          <td>{formatCurrency(total)}</td>
        </tr>
      </tfoot>
    </table>
  );
};

SummaryTable.displayName = 'SummaryTable';

export default SummaryTable;
