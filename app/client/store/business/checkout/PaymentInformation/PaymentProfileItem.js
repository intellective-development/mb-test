import React from 'react';
import { css } from '@amory/style/umd/style';
import { usePaymentProfileItem } from 'modules/paymentProfile/hooks';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';
import icon from '../shared/MBIcon/MBIcon';
import EditButton from '../shared/EditButton';

const PaymentProfileItem = ({ id }) => {
  const {
    expires,
    name,
    network,
    type,
    number,
    onDeleteProfile,
    onSelectDefaultProfile
  } = usePaymentProfileItem(id);
  return (
    <tr
      key={id}>
      <td className={css([unstyle.td, styles.cctd])}>
        {name}
      </td>
      <td
        className={css([
          unstyle.td,
          styles.cctd,
          icon({
            name: network,
            style: {
              height: 36,
              width: 36
            }
          })
        ])}
        title={type} />
      <td className={css([unstyle.td, styles.cctd])}>
        {number}
      </td>
      <td className={css([unstyle.td, styles.cctd])}>
        Expires {expires}
      </td>
      <td
        className={css([
          unstyle.td,
          styles.cctd,
          styles.ccselect
        ])}>
        <EditButton onClick={() => onSelectDefaultProfile(id)}>
          Select
        </EditButton>
      </td>
      <td
        className={css([
          unstyle.td,
          styles.cctd,
          styles.ccselect
        ])}>
        <EditButton onClick={() => onDeleteProfile(id)}>
          Delete
        </EditButton>
      </td>
    </tr>
  );
};

export default PaymentProfileItem;
