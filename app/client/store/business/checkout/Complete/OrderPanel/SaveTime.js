import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React, { Fragment, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';

import { CreateButton } from './CreateButton';
import { PasswordInput } from './PasswordInput';

import fonts from '../../shared/MBElements/MBFonts.css.json';
import styles from './OrderPanel.css.json';
import { SetGuestPassword, selectGuestPassword, SaveGuestPasswordProcedure, selectGuestPasswordCreated, selectIsUserGuest } from '../../../../../modules/checkout/checkout.dux';

export const SaveTime = ({
  postCheckout
}) => {
  const dispatch = useDispatch();
  const [error, setError] = useState();
  const passwordCreated = useSelector(selectGuestPasswordCreated);
  const value = useSelector(selectGuestPassword);
  const isGuest = useSelector(selectIsUserGuest);
  const onChange = e => {
    setError();
    dispatch(SetGuestPassword(e.target.value));
  };
  const onClick = () => {
    return SaveGuestPasswordProcedure(value)
      .catch(e => {
        const message = e.error && e.error.message;
        setError(message);
      });
  };

  if (!isGuest && !passwordCreated){
    return null;
  }

  if (passwordCreated){
    return (
      <div className={css([
        fonts.common,
        styles.a,
        postCheckout ? styles.r : styles.s
      ])}>
        <div className={css(styles.e)}>
          <span className={css(styles.f)}>
            ACCOUNT CREATED
          </span>
        </div>
        <div className={css([styles.h, postCheckout ? {} : styles.g])}>
          {'Your account was created. You\'ll receive an email confirmation shortly.'}
        </div>
      </div>
    );
  }

  return (
    <div className={css([
      fonts.common,
      styles.a,
      postCheckout ? styles.r : styles.s
    ])}>
      <div className={css(styles.e)}>
        <span className={css(styles.f)}>
          Save Time, Next Time
        </span>
        {postCheckout && (
          <Fragment>
            &nbsp;
            <em className={css(styles.g)}>
              (optional)
            </em>
          </Fragment>
        )}
      </div>
      <div className={css([styles.h, postCheckout ? {} : styles.g])}>
        Enter a password below and we’ll create an account for you.
      </div>
      <div className={css(styles.m)}>
        {/* https://medium.com/paul-jaworski/turning-off-autocomplete-in-chrome-ee3ff8ef0908 */}
        <input
          type="hidden"
          value="autocomplete-disabler" />
        <PasswordInput value={value} onChange={onChange} autoComplete="new-password" />
        {postCheckout && <CreateButton onClick={onClick} />}
      </div>
      {error && <div className={css([styles.h, { color: 'red' }])}>
        {error}
      </div>}
    </div>
  );
};

SaveTime.defaultProps = {
  postCheckout: true
};

SaveTime.displayName = 'SaveTime';

SaveTime.propTypes = {
  postCheckout: PropTypes.bool
};

export default SaveTime;
