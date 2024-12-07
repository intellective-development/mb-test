import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import { useToggle } from '../../shared/use-toggle';

import { AccountCreated } from './AccountCreated';
import { EmailLink } from './EmailLink';
import { OrderPlaced } from './OrderPlaced';
import { PhoneLink } from './PhoneLink';
import { SaveTime } from './SaveTime';

import styles from './OrderPanel.css.json';

export const OrderPanel = ({ orderNum }) => {
  const [toggle, _setToggle] = useToggle(true);

  return (
    <React.Fragment>
      <div className={css(styles.p)}>
        <OrderPlaced orderNum={orderNum} />
        <div className={css(styles.q)}>
          <PhoneLink />
          <EmailLink />
        </div>
      </div>

      <div className={css(styles.p)}>
        {toggle
          ? <SaveTime />
          : <AccountCreated />}
      </div>
    </React.Fragment>
  );
};

OrderPanel.displayName = 'OrderPanel';

OrderPanel.propTypes = {
  orderNum: PropTypes.number.isRequired
};

export default OrderPanel;
