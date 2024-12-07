import createProcedure from 'redux-procedures';
import { groupBy } from 'lodash';
import { createSelector } from 'reselect';
import * as api from '@minibar/store-business/src/networking/api';

const localState = ({ scheduling_calendar }) => scheduling_calendar;

export const selectSchedulingByDeliveryMethodId = state => id => localState(state).by_id[id];
export const getHoursGroupedByDate = createSelector(
  selectSchedulingByDeliveryMethodId,
  schedulingByDeliveryMethodId => id => {
    const { scheduling_days } = schedulingByDeliveryMethodId(id) || {};
    return groupBy(scheduling_days, 'date');
  }
);

const fetchSchedulingCalendar = (payload, meta, store) => {
  return api.fetchSchedulingCalendar(payload)
    .then(response => {
      store.dispatch({
        type: 'SCHEDULING_CALENDAR:FETCH_CALENDAR__SUCCESS', // TODO: backward compat
        payload: response
      });
    });
};

export const FetchCalendarProcedure = createProcedure('FETCH_SCHEDULE', fetchSchedulingCalendar);
