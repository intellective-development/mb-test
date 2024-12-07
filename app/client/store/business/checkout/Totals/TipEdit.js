import { css } from '@amory/style/umd/style';
import React, { Fragment } from 'react';
import { toFixed } from 'modules/utils';
import unstyle from '../shared/MBElements/MBUnstyle.css.json';
import styles from '../Checkout.css.json';

const TipEdit = ({
  inputEl,
  setTipEditing,
  tip,
  tipEditing = true,
  updateTip
}) => (
  <div className={css(styles.tipline)}>
    {tipEditing
      ? (
        <Fragment>
          <button
            className={css([
              unstyle.button,
              styles.tipbutton
            ])}
            onClick={updateTip}>
            Save
          </button>
          <input
            className={css(styles.tipedit)}
            ref={inputEl}
            defaultValue={toFixed(tip, 2)}
            onBlur={updateTip}
            size={5}
            type="text" />
        </Fragment>
      )
      : (
        <Fragment>
          <button
            className={css([unstyle.button, styles.edit])}
            onClick={() => setTipEditing(true)}>
            Edit
          </button>
          &nbsp;
          <span>
            ${toFixed(tip, 2)}
          </span>
        </Fragment>
      )
    }
  </div>
);

export default TipEdit;
