import { create, css } from '@amory/style/umd/style';
import { compact } from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';

import { fonts, unstyle } from '../../../style/index';

import StoreEntry from '../../../compounds/StoreEntry/index';

import styles from './RegionsHero.css.json';

export const RegionsHero = ({
  image,
  name,
  tagline
}) => {
  const title = ['Alcohol Delivery in', name].join(' ');

  create(fonts);

  return (
    <div
      className={css([
        {
          backgroundImage: compact([
            'linear-gradient(rgba(0,0,0,.4),rgba(0,0,0,.4))',
            image ? ['url(', image, ')'].join("'") : null
          ])
        },
        styles.hero
      ])}
      id="region-hero">
      <h1 className={css([unstyle.h, fonts.headline, styles.headline])}>
        {title}
      </h1>
      <p className={css([unstyle.p, fonts.common, styles.tagline])}>
        {tagline}
      </p>
      <StoreEntry
        className={css(styles.entry)}
        destination="/store/"
        submit_button_text="Shop Now" />
    </div>
  );
};

RegionsHero.defaultProps = {
  tagline: 'Wine, beer, and liquor delivered in as little as 30–60 minutes.'
};

RegionsHero.displayName = 'RegionsHero';

RegionsHero.propTypes = {
  name: PropTypes.string.isRequired,
  slug: PropTypes.string.isRequired,
  tagline: PropTypes.string
};

export default RegionsHero;
