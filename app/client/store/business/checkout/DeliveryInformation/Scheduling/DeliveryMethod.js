import { css } from '@amory/style/umd/style';
import { map, compact, get } from 'lodash';
import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import {
  selectSupplierById,
  selectSelectedDeliveryMethodBySupplierId,
  setDeliveryMethod as setDeliveryMethodAction
} from 'modules/supplier/supplier.dux';
import { selectDeliveryMethodById } from 'modules/deliveryMethod/deliveryMethod.dux';
import { SetDeliveryMethodSchedule, selectCheckoutSchedulingByDeliveryMethodId } from 'modules/checkout/checkout.dux';
import { delivery_method_helpers } from 'store/business/delivery_method';
import fonts from '../../shared/MBElements/MBFonts.css.json';
import icon from '../../shared/MBIcon/MBIcon';
import styles from '../../Checkout.css.json';
import PickupDetails from './PickupDetails';
import SchedulePicker from './SchedulePicker';


export const DeliveryMethod = ({ supplierId }) => {
  const dispatch = useDispatch();
  const setDeliveryMethod = deliveryMethodId => {
    dispatch(setDeliveryMethodAction(parseInt(supplierId), parseInt(deliveryMethodId)));
  };
  const supplier = useSelector(selectSupplierById)(supplierId) || {};
  const deliveryMethodById = useSelector(selectDeliveryMethodById);
  const selected = useSelector(selectSelectedDeliveryMethodBySupplierId)[supplierId];
  const selectedDeliveryMethod = deliveryMethodById[selected];
  const setDeliveryMethodSchedule = (schedule, id) => {
    dispatch(SetDeliveryMethodSchedule({ schedule, id }));
  };
  const checkoutSchedulesById = useSelector(selectCheckoutSchedulingByDeliveryMethodId) || {};
  const selectedSchedule = !!checkoutSchedulesById && get(checkoutSchedulesById[selected], 'schedule', false);

  const deliveryMethods = compact(map(supplier.delivery_methods, id => deliveryMethodById[id]));

  const time_zone = get(supplier, 'time_zone');

  useEffect(() => {
    if (delivery_method_helpers.mustBeScheduled(selectedDeliveryMethod) && !selectedSchedule){
      setDeliveryMethodSchedule(true, selected);
    }
  }, []);

  return (
    <React.Fragment>
      <div
        className={css([
          fonts.common,
          styles.deliverymethods,
          { flex: 1 }
        ])}>
        {map(deliveryMethods, (deliveryMethod) => {
          const { allows_scheduling, delivery_expectation, id } = deliveryMethod;
          const schedule = !!checkoutSchedulesById && get(checkoutSchedulesById[id], 'schedule', false);
          const checked = selected === id && !schedule;
          const scheduling = selected === id && schedule;
          const scheduleReq = delivery_method_helpers.mustBeScheduled(deliveryMethod);

          return (
            <div>
              {!scheduleReq && (
                <label
                  className={css([
                    checked
                      ? icon({
                        color: '#3b87fd',
                        name: 'done'
                      })
                      : icon({
                        color: 'none',
                        name: 'circle',
                        stroke: '#9b9b9b'
                      }),
                    styles.deliveryoption
                  ])}
                  htmlFor={`delivery-method-${supplierId}-${id}`}>
                  <input
                    checked={checked}
                    className={css(styles.hide)}
                    id={`delivery-method-${supplierId}-${id}`}
                    name="deliveryMethod"
                    onChange={() => {
                      setDeliveryMethod(id);
                      setDeliveryMethodSchedule(false, id);
                    }}
                    type="radio"
                    value={id} />
                  {delivery_expectation}
                  <PickupDetails
                    address={get(supplier, 'address')}
                    checked={checked}
                    delivery_expectation={delivery_expectation} />
                </label>
              )}
              {allows_scheduling && <label
                className={css([
                  scheduling
                    ? icon({
                      color: '#3b87fd',
                      name: 'done'
                    })
                    : icon({
                      color: 'none',
                      name: 'circle',
                      stroke: '#9b9b9b'
                    }),
                  styles.deliveryoption
                ])}
                htmlFor={`delivery-method-schedule-${supplierId}-${id}`}>
                <input
                  checked={scheduling}
                  className={css(styles.hide)}
                  id={`delivery-method-schedule-${supplierId}-${id}`}
                  name="deliveryMethod"
                  onChange={() => {
                    setDeliveryMethod(id);
                    setDeliveryMethodSchedule(true, id);
                  }}
                  type="radio"
                  value={`${id}-selected`} />
                Schedule delivery
              </label>}
            </div>
          );
        })}
        {selectedDeliveryMethod.allows_scheduling && selectedSchedule && <SchedulePicker deliveryMethodId={selected} time_zone={time_zone} />}
      </div>
    </React.Fragment>
  );
};

export default DeliveryMethod;
