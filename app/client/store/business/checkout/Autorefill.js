import { css } from '@amory/style/umd/style';
import { map } from 'lodash';
import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { SetReplenishment, selectReplenishment } from 'modules/checkout/checkout.dux';
import MBSelect from './shared/MBSelect/MBSelect';
import Panel from './shared/Panel';
import PanelTitle from './shared/PanelTitle';
import Row from './shared/Row';
import styles from './Checkout.css.json';

const options = [
  { value: 7, label: 'Repeat Weekly' },
  { value: 14, label: 'Repeat every 2 weeks' },
  { value: 21, label: 'Repeat every 3 weeks' },
  { value: 28, label: 'Repeat every 4 weeks' }
];

export default () => {
  const { enabled, interval } = useSelector(selectReplenishment) || {};
  const dispatch = useDispatch();
  return (
    <Panel id="auto-refill">
      <div className={css(styles.header)}>
        <PanelTitle id="auto-refill">
          Auto-Refill
        </PanelTitle>
      </div>
      <Row style={{ margin: 5 }}>
        <div>
          <input
            value={enabled}
            checked={enabled}
            onChange={e => dispatch(SetReplenishment({ enabled: e.target.checked }))}
            id="enable_replenishment"
            type="checkbox" />
        </div>
        <label
          className={css([
            styles.p,
            {
              color: '#757575',
              letterSpacing: 'normal',
              paddingLeft: 10
            }
          ])}
          htmlFor="enable_replenishment">
          Automatically re-order this/these item(s) on a flexible schedule.
          &nbsp;You’ll receive a reminder the day before your order and you
          can cancel your subscription at any time from the account page.
          &nbsp;Your order will be set up for the same time as your initial
          order.
        </label>
      </Row>
      <Row>
        <div className={css({
          padding: '10px 5px',
          width: '100%'
        })}>
          <MBSelect
            onChange={e => dispatch(SetReplenishment({ interval: parseInt(e.target.value) }))}
            style={{ width: '100%' }}>
            {map(options, ({ label, value }) => (
              <option
                selected={value === interval}
                key={value}
                value={value}>
                {label}
              </option>
            ))}
          </MBSelect>
        </div>
      </Row>
    </Panel>
  );
};
