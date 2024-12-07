// @flow

import * as React from 'react';
import _ from 'lodash';
import moment from 'moment';
import { connect } from 'react-redux';
import cn from 'classnames';
import I18n from 'store/localization';
import * as Ent from '@minibar/store-business/src/utils/ent';
import * as date_helpers from '@minibar/store-business/src/utils/format_date';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { order_actions } from 'store/business/order';
import * as shipment_helpers from 'legacy_store/models/Shipment';
import { scheduling_calendar_actions } from 'store/business/scheduling_calendar';
import type { SchedulingCalendar } from 'store/business/scheduling_calendar';

import { MBText } from '../../../elements';

type SchedulingPickerProps = {
  shipment: Object,
  scheduling_calendar: SchedulingCalendar,
  resetShipmentScheduling: Function,
  setShipmentScheduling: Function,
  fetchCalendar: Function
};
type SchedulingPickerState = {loading_calendar: boolean, selected_date: ?string};
class SchedulingPicker extends React.PureComponent<SchedulingPickerProps, SchedulingPickerState> {
  constructor(props: SchedulingPickerProps){
    super(props);

    if (!props.scheduling_calendar){
      props.fetchCalendar(props.shipment.delivery_method.id);
      this.state = {loading_calendar: true, selected_date: null};
    } else {
      const initial_date = this.initialSchedulingDay(props.shipment.scheduled_for, props.scheduling_calendar);
      this.state = {loading_calendar: false, selected_date: initial_date};
    }
  }

  componentWillReceiveProps(next_props){
    if (!this.props.scheduling_calendar && next_props.scheduling_calendar){
      const initial_date = this.initialSchedulingDay(next_props.shipment.scheduled_for, next_props.scheduling_calendar);
      this.setState({loading_calendar: false, selected_date: initial_date});
    } else if (this.props.scheduling_calendar && !next_props.scheduling_calendar){
      next_props.fetchCalendar(next_props.shipment.delivery_method.id);
      this.setState({loading_calendar: true, selected_date: null});
    }
  }

  initialSchedulingDay = (scheduled_for, scheduling_calendar) => {
    if (!scheduled_for) return null;

    const scheduled_for_moment = moment.parseZone(scheduled_for);
    const scheduled_day = scheduling_calendar.scheduling_days.find(day => (
      moment.parseZone(day.windows[0].start_time).isSame(scheduled_for_moment, 'day')
    ));
    return scheduled_day ? scheduled_day.date : null;
  }

  selectSchedulingDay = (date: string) => {
    this.props.resetShipmentScheduling(!!date, this.props.shipment.supplier.id);
    this.setState({selected_date: date});
  }

  selectSchedulingWindow = (scheduled_for: string) => {
    this.props.setShipmentScheduling(scheduled_for, this.props.shipment.supplier.id);
  }

  render(){
    const { selected_date, loading_calendar } = this.state;
    const { shipment, scheduling_calendar } = this.props;
    const { delivery_method } = shipment;

    if (!delivery_method_helpers.deliveryMethodCanBeScheduled(delivery_method)) return null;
    if (loading_calendar) return <SchedulingLoader />;

    const selected_scheduling_day = scheduling_calendar.scheduling_days.find(day => day.date === selected_date);
    const must_be_scheduled = delivery_method_helpers.mustBeScheduled(delivery_method);
    const scheduling_windows = selected_scheduling_day ? selected_scheduling_day.windows : [];

    return (
      <form className="csl__scheduling__container">
        <SchedulingLabel shipment={shipment} />
        <div className="csl__scheduling__select-container">
          <DateSelect
            scheduling_dates={scheduling_calendar.scheduling_days.map(day => day.date)}
            selected_date={selected_date}
            required={must_be_scheduled}
            selectSchedulingDay={this.selectSchedulingDay} />
          <TimeSelect
            windows={scheduling_windows}
            selected_window={shipment.scheduled_for}
            disabled={!selected_scheduling_day}
            selectSchedulingWindow={this.selectSchedulingWindow} />
        </div>
      </form>
    );
  }
}

const SchedulingLabel = ({shipment}) => {
  const error = shipment_helpers.validateShipment(shipment);
  const content_path = error ? error.name : 'scheduling_prompt';
  const classes = cn('csl__scheduling__section-label', {
    'csl__scheduling__section-label--error': !!error
  });

  return (
    <MBText.P className={classes}>
      {I18n.t(`ui.body.checkout_shipment.${content_path}`, {
        delivery_method_type: delivery_method_helpers.displayNameShort(shipment.delivery_method).toLowerCase()
      })}
    </MBText.P>
  );
};

const DateSelect = ({scheduling_dates = [], selected_date, required, selectSchedulingDay}) => {
  const default_prompt = required ? 'Select Date' : 'ASAP';
  const default_value = '';

  return (
    <select
      name="date"
      className="csl__scheduling__date-select"
      value={selected_date || default_value}
      onChange={e => selectSchedulingDay(e.target.value)}>
      <option value={default_value}>{default_prompt}</option>
      {scheduling_dates.map(date => (
        <option value={date} key={date}>{formatWindowDate(date)}</option>
      ))}
    </select>
  );
};

const TimeSelect = ({windows = [], selected_window, disabled, selectSchedulingWindow}) => {
  const default_value = '';

  return (
    <select
      name="time"
      className="csl__scheduling__time-select"
      disabled={disabled}
      value={selected_window || default_value}
      onChange={e => selectSchedulingWindow(e.target.value)}>
      <option value={default_value} disabled style={{display: 'none'}}>Select Time</option>
      {windows.map(window => (
        <option value={window.start_time} key={window.start_time}>
          {date_helpers.formatTime(window.start_time)} - {date_helpers.formatTime(window.end_time)}
        </option>
      ))}
    </select>
  );
};

const SchedulingLoader = () => {
  return <div className="csl__scheduling__loader" />;
};

const SchedulingPickerSTP = () => {
  const findCalendar = Ent.find('scheduling_calendar');

  return (state, {shipment}) => ({
    scheduling_calendar: findCalendar(state, shipment.delivery_method.id)
  });
};
const SchedulingPickerDTP = {
  resetShipmentScheduling: order_actions.resetShipmentScheduling,
  setShipmentScheduling: order_actions.setShipmentScheduling,
  fetchCalendar: scheduling_calendar_actions.fetchCalendar
};
const SchedulingPickerContainer = connect(SchedulingPickerSTP, SchedulingPickerDTP)(SchedulingPicker);

export default SchedulingPickerContainer;

// helpers

// returns whether ISO 8601 timestamp is today in it's own timezone
export const isToday = (date: string) => {
  const date_moment = moment.parseZone(date);
  return moment(date_moment).format('YYMMDD') === moment().format('YYMMDD');
};

const formatWindowDate = (date) => {
  if (!date) return '';
  const month_and_day = moment.parseZone(date).format('MMM D');
  const day_name = isToday(date) ? _.startCase(I18n.t('global.day.today')) : _.startCase(date_helpers.formatDayName(date, {short: true}));
  return `${day_name}, ${month_and_day}`; // e.g. Today, Aug 22 || Thu, Aug 24
};
