import { css } from '@amory/style/umd/style';
import { capitalize, get, toNumber } from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';

import unstyle from '../../../style/unstyle.json';
import styles from './LiquorStore.css.json';

export const LiquorStore = ({
  addressLocality,
  addressRegion,
  as: Element,
  categories,
  className,
  image,
  latitude,
  longitude,
  name,
  postalCode,
  priceRange,
  streetAddress,
  style,
  telephone,
  url,
  ...props
}) =>
  (
    <Element
      className={css([styles.store, style], className)}
      itemScope
      itemType="https://schema.org/LiquorStore"
      {...props}>
      <meta
        content={image}
        itemProp="image" />
      <h3
        className={css(styles.name)}
        itemProp="name">
        <a
          className={css([unstyle.a, styles.link])}
          href={url}
          itemProp="url">
          {name}
        </a>
      </h3>
      <div
        className={css(styles.address)}
        itemProp="address"
        itemScope
        itemType="https://schema.org/PostalAddress">
        <span itemProp="streetAddress">
          {streetAddress}
        </span>
        {', '}
        <span itemProp="addressLocality">
          {addressLocality}
        </span>
        {', '}
        <span itemProp="addressRegion">
          {addressRegion}
        </span>
        {' '}
        <span itemProp="postalCode">
          {postalCode}
        </span>
      </div>
      <span
        itemProp="geo"
        itemScope
        itemType="https://schema.org/GeoCoordinates">
        <meta
          content={latitude}
          itemProp="latitude" />
        <meta
          content={longitude}
          itemProp="longitude" />
      </span>
      <meta
        content={priceRange}
        itemProp="priceRange" />
      <div
        className={css(styles.telephone)}
        itemProp="telephone">
        {telephone}
      </div>
      <ul
        className={css([unstyle.ul, styles.ul])}
        itemProp="hasOfferCatalog"
        itemScope
        itemType="https://schema.org/OfferCatalog">
        {['wine', 'liquor', 'beer', 'mixers'].map((key) =>
          (toNumber(get(categories, key)) > 0
            ? (
              <li
                className={css([unstyle.li, styles.li, styles[key]])}
                itemProp="itemListElement"
                key={key}>
                {capitalize(key)}
              </li>
            )
            : null)
        )}
      </ul>
    </Element>
  );

LiquorStore.defaultProps = {
  as: 'div',
  image: 'https://minibardelivery.com/assets/touch-icon-3f5064b586096a6969344bd805a0713d.png',
  priceRange: '$',
  style: {}
};

LiquorStore.displayName = 'LiquorStore';

LiquorStore.propTypes = {
  addressLocality: PropTypes.string.isRequired,
  addressRegion: PropTypes.string.isRequired,
  as: PropTypes.elementType,
  categories: PropTypes.shape({
    beer: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ]),
    liquor: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ]),
    mixers: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ]),
    wine: PropTypes.oneOfType([
      PropTypes.number,
      PropTypes.string
    ])
  }).isRequired,
  className: PropTypes.string,
  image: PropTypes.string,
  latitude: PropTypes.number.isRequired,
  longitude: PropTypes.number.isRequired,
  name: PropTypes.string.isRequired,
  postalCode: PropTypes.string.isRequired,
  priceRange: PropTypes.string,
  streetAddress: PropTypes.string.isRequired,
  style: PropTypes.object,
  telephone: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired
};

export default LiquorStore;
