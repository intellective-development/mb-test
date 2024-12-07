import { create, css } from '@amory/style/umd/style';
import { compact } from 'lodash-es';
import PropTypes from 'prop-types';
import React from 'react';

import {
  fonts,
  mobile,
  retina,
  unstyle
} from '../../../style/index';

import styles from './RegionInfo.css.json';

export const RegionInfo = ({
  'as': Element,
  className,
  description,
  name,
  style,
  ...props
}) => {
  const texts = compact(description.split('\\n'));
  const title = ['Minibar Delivery in', name].join(' ');

  create(fonts);

  return (
    <Element
      className={css([
        mobile(
          styles.divMobile,
          styles.divDesktop
        ),
        styles.div,
        style
      ], className)}
      {...props}>
      <div
        className={css([
          mobile(
            styles.imgMobile,
            styles.imgDesktop
          ),
          retina(
            styles.imgRetina,
            styles.imgStandard
          ),
          styles.img
        ])} />
      <div
        className={css([
          fonts.common,
          styles.info
        ])}>
        <h2
          className={css([
            unstyle.h,
            styles.title
          ])}>
          {title}
        </h2>
        {texts.map((text) =>
          (
            <p
              className={css([
                unstyle.p,
                styles.text
              ])}
              key={text}>
              {text}
            </p>
          ))}
      </div>
    </Element>
  );
};

RegionInfo.defaultProps = {
  as: 'div',
  style: {}
};

RegionInfo.displayName = 'RegionInfo';

RegionInfo.propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  description: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  style: PropTypes.object
};

export default RegionInfo;
