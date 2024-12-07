import { css } from '@amory/style/umd/style';
import { isEmpty, get } from 'lodash';
import m from 'moment-timezone';
import React, { Fragment, useEffect } from 'react';
import { useSelector } from 'react-redux';

import {
  selectSelectedDeliveryMethodBySupplierId,
  selectSupplierById
} from 'modules/supplier/supplier.dux';
import {
  FetchCalendarProcedure
} from 'modules/scheduling/scheduling.dux';
import {
  selectDeliveryMethodById
} from 'modules/deliveryMethod/deliveryMethod.dux';
import {
  delivery_method_helpers
} from 'store/business/delivery_method';
import {
  selectCheckoutAddressEditing,
  selectCheckoutSchedulingByDeliveryMethodId
} from 'modules/checkout/checkout.dux';

// import styles from '../../Checkout.css.json';
import colors from '../../shared/MBElements/MBColors.css.json';
import unstyle from '../../shared/MBElements/MBUnstyle.css.json';
import icon from '../../shared/MBIcon/MBIcon';
import Row from '../../shared/Row';

import DeliveryMethod from './DeliveryMethod';

export const SupplierSchedule = ({ supplierId }) => {
  const supplier = useSelector(selectSupplierById)(supplierId) || {};
  const time_zone = get(supplier, 'time_zone');
  const delivery_method_id = useSelector(selectSelectedDeliveryMethodBySupplierId)[supplierId];
  const deliveryMethodById = useSelector(selectDeliveryMethodById);
  const selectedDeliveryMethod = deliveryMethodById[delivery_method_id] || {};
  const isEditing = useSelector(selectCheckoutAddressEditing);
  const isClosed = delivery_method_helpers.isClosed(selectedDeliveryMethod);

  useEffect(() => {
    selectedDeliveryMethod.allows_scheduling && FetchCalendarProcedure({ delivery_method_id });
  }, [selectedDeliveryMethod, delivery_method_id]);

  const schedule = useSelector(selectCheckoutSchedulingByDeliveryMethodId)[delivery_method_id] || {};

  const momentDay = m(schedule.day);
  const mustSchedule = delivery_method_helpers.mustBeScheduled(selectedDeliveryMethod) && !(schedule.hour || momentDay.isValid());

  let deliveryDay;
  let deliveryTime;

  switch (true){
    case schedule.hour && momentDay.isValid():
      deliveryDay = momentDay.format('ll');
      break;
    case isClosed:
      deliveryDay = null;
      break;
    default:
      deliveryDay = selectedDeliveryMethod.delivery_expectation;
      break;
  }

  if (!isEmpty(get(schedule, 'hour'))){
    const startTime = get(schedule, 'hour.start_time');
    const endTime = get(schedule, 'hour.end_time');
    const momentStartHour = m(startTime).tz(time_zone);
    const momentEndHour = m(endTime).tz(time_zone);
    const displayStartHour = momentStartHour.isValid() ? momentStartHour.format('h:mma') : startTime;
    const displayEndHour = momentEndHour.isValid() ? momentEndHour.format('h:mma') : endTime;
    deliveryTime = `${displayStartHour} - ${displayEndHour}`;
  }

  return (
    <Fragment>
      <Row>
        <div
          className={css([
            icon({ name: 'storefront' }),
            {
              '::before': {
                boxSizing: 'border-box',
                margin: 5
              },
              'alignItems': 'center',
              'display': 'flex',
              'flexDirection': 'row',
              'flexGrow': 1,
              'margin': '0 0 10px'
            }
          ])}>
          <div>
            {isClosed && (
              <div
                className={css({
                  color: colors.brandRed,
                  fontSize: 13,
                  fontWeight: 700,
                  lineHeight: 1.4
                })}>
                Closed
              </div>
            )}
            <h4
              className={css([
                unstyle.h,
                {
                  alignItems: 'center',
                  color: '#757575',
                  display: 'flex',
                  flexGrow: 1,
                  fontSize: 15,
                  fontWeight: 700,
                  textTransform: 'uppercase'
                }
              ])}>
              {supplier.name}
            </h4>
          </div>
        </div>
        <div
          className={css({
            color: '#999',
            fontSize: 13,
            fontWeight: 700,
            margin: 5,
            textAlign: 'right',
            whiteSpace: 'nowrap'
          })}>
          {deliveryDay && (<div>{deliveryDay}</div>)}
          {deliveryTime && (<div>{deliveryTime}</div>)}
        </div>
      </Row>
      <Row>
        {isClosed &&
          (<span className={css({
            color: colors.brandRed,
            fontSize: 13,
            fontStyle: 'italic',
            margin: '5px 5px 10px'
          })}>
            {delivery_method_helpers.formatNextDelivery(selectedDeliveryMethod)}
          </span>)}
      </Row>
      <Row>
        { !isEditing && mustSchedule && (
          <span className={css({
            color: colors.brandRed,
            fontSize: 13,
            fontStyle: 'italic',
            margin: '5px 5px 10px'
          })}>
            Please Edit to schedule this delivery.
          </span>
        )}
        { isEditing && (
          <DeliveryMethod
            supplierId={supplierId} />
        )}
      </Row>
      <Row>
        {schedule.schedule && time_zone && (<div
          id="supplier-timezone-notice"
          className={css({
            color: '#9b9b9b',
            fontSize: 13,
            fontStyle: 'italic',
            margin: '0px 10px'
          })}>
          All dates and times displayed in {time_zone.replace(/_/g, ' ')} time zone.
        </div>)}
      </Row>
    </Fragment>
  );
};

export default SupplierSchedule;
