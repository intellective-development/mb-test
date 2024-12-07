import React from 'react';
import { css } from '@amory/style/umd/style';
import styles from '../Checkout.css.json';

// @flow
export const deliveryCost = (shoprunner: boolean, fallback: string | JSX.Element, containerClass?: string = 'shoprunner__container') => (
  shoprunner ? (
    <div className={`_SRD ${css([styles[containerClass]])}`}>
      <div className={`srd_iconline ${css([styles.shoprunner])}`}>
        <div className="srd_logo" />
      </div>
    </div>
  ) : fallback
);

export default deliveryCost;
