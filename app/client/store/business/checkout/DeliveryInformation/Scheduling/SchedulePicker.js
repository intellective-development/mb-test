import { css } from '@amory/style/umd/style';
import React, { Fragment } from 'react';
import m from 'moment-timezone';
import { compact, map, isEmpty, get, head, isEqual } from 'lodash';
import { useDispatch, useSelector } from 'react-redux';
import {
  SetDeliveryMethodSchedule,
  selectCheckoutSchedulingByDeliveryMethodId
} from 'modules/checkout/checkout.dux';
import {
  getHoursGroupedByDate,
  selectSchedulingByDeliveryMethodId
} from 'modules/scheduling/scheduling.dux';
import { Labeled } from '../../shared/elements';
import MBSelect from '../../shared/MBSelect/MBSelect';
import icon from '../../shared/MBIcon/MBIcon';
import styles from '../../Checkout.css.json';

const SchedulePicker = ({ deliveryMethodId, time_zone }) => {
  // TODO: move to hook?
  // TODO: simplify
  const dispatch = useDispatch();
  const schedule = useSelector(selectCheckoutSchedulingByDeliveryMethodId)[deliveryMethodId] || {};
  const { scheduling_days } = useSelector(selectSchedulingByDeliveryMethodId)(deliveryMethodId) || {};
  const formatDayToOption = date => ({
    label: m.tz(date.date, time_zone).format('ddd, MMM D'),
    value: date.date
  });
  const formatHourToOption = hour => ({
    label: `${m(hour.start_time).tz(time_zone).format('h:mma')}-${m(hour.end_time).tz(time_zone).format('h:mma')}`,
    value: hour
  });
  const days = map(scheduling_days, formatDayToOption);
  const dayHours = useSelector(getHoursGroupedByDate)(deliveryMethodId) || {};
  const selectedDayHours = dayHours[schedule.day];
  const daySelected = !isEmpty(selectedDayHours);
  const selectableHours = compact(map(get(head(selectedDayHours), 'windows'), formatHourToOption)) || [];

  const setSchedule = ({ day = schedule.day, hour }) => {
    dispatch(SetDeliveryMethodSchedule({
      id: deliveryMethodId,
      day,
      hour,
      schedule: true
    }));
  };
  const setDay = (day) => setSchedule({ day });
  const setHour = (hour) => setSchedule({ hour });

  return (
    <Fragment>
      <div className={css({
        display: 'flex',
        flexDirection: 'row'
      })}>
        <Labeled
          id={`schedule-delivery-option-date-${deliveryMethodId}`}
          style={styles.delivery}>
          <MBSelect
            id={`schedule-delivery-option-date-${deliveryMethodId}`}
            onChange={(e) => setDay(e.target.value)}
            style={{
              ...styles.select,
              backgroundImage: [
                icon({
                  color: '#757575',
                  name: 'date'
                })['::before'].backgroundImage
              ]
            }}>
            <option>Select a date</option>
            {map(days, ({ label, value }) => (
              <option
                key={label}
                selected={value === schedule.day}
                value={value}>
                {label}
              </option>
            ))}
          </MBSelect>
          {!schedule.day && <div className={css(styles.header)}>
            <div className="csl__delivery__closed">Schedule a date of your delivery</div>
          </div>}
        </Labeled>
        <Labeled
          id={`schedule-delivery-option-time-${deliveryMethodId}`}
          style={styles.delivery}>
          <MBSelect
            disabled={!daySelected}
            onChange={e => { setHour(e.target.value && JSON.parse(e.target.value)); }}
            id={`schedule-delivery-option-time-${deliveryMethodId}`}
            style={{
              ...styles.select,
              backgroundImage: [
                icon({
                  color: '#757575',
                  name: 'clock'
                })['::before'].backgroundImage
              ]
            }}>
            <option>Select an hour</option>
            {map(selectableHours, ({ label, value }) => (
              <option
                key={JSON.stringify(value)}
                selected={isEqual(value, schedule.hour)}
                value={JSON.stringify(value)}>
                {label}
              </option>
            ))}
          </MBSelect>
          {schedule.day && !schedule.hour && <div className={css(styles.header)}>
            <div className="csl__delivery__closed">Schedule a time for your delivery</div>
          </div>}
        </Labeled>
      </div>
    </Fragment>
  );
};

export default SchedulePicker;
