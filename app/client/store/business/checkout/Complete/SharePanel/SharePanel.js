import { css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import { EmailButton } from './EmailButton';
import { FacebookButton } from './FacebookButton';
import { Give10Get10 } from './Give10Get10';
import { PromoCode } from './PromoCode';
import { ShareWithFriends } from './ShareWithFriends';
import { TwitterButton } from './TwitterButton';

import styles from './SharePanel.css.json';

export const SharePanel = ({ promoCode }) =>
  (
    <div className={css(styles.a)}>
      <ShareWithFriends />
      <div className={css(styles.e)}>
        <Give10Get10 />
        <div className={css(styles.i)}>
          <PromoCode promoCode={promoCode} />
          <TwitterButton promoCode={promoCode} />
          <FacebookButton promoCode={promoCode} />
          <EmailButton promoCode={promoCode} />
        </div>
      </div>
    </div>
  );

SharePanel.displayName = 'SharePanel';

SharePanel.propTypes = {
  promoCode: PropTypes.string
};

export default SharePanel;
