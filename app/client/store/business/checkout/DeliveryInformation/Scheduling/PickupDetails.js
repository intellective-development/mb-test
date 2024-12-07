import { css } from '@amory/style/umd/style';
import { compact, get } from 'lodash';
import React from 'react';

export const PickupDetails = ({ address, checked, delivery_expectation }) =>
  (checked && delivery_expectation === 'In-store pickup' ? (
    <span className={css({ fontStyle: 'italic' })}>
      &nbsp;
      ({compact([
        get(address, 'address1'),
        get(address, 'address2'),
        get(address, 'city'),
        get(address, 'state'),
        get(address, 'zip_code')
      ]).join(', ')})
    </span>
  ) : null);

export default PickupDetails;
