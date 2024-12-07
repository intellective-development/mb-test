import { create, css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React from 'react';

import icon from '../../../../business/checkout/shared/MBIcon/MBIcon';
import { fonts, unstyle } from '../../../style/index';

import styles from './RegionTestimonials.css.json';

export const RegionTestimonials = ({
  'as': Element,
  author,
  className,
  name,
  review,
  style,
  ...props
}) => {
  const title = [
    'Featured customer review in',
    name
  ].join(' ');

  create(fonts);

  return (
    <Element
      className={css([
        fonts.common,
        styles.section,
        style
      ], className)}
      {...props}>
      <h2
        className={css([
          unstyle.h,
          icon({
            color: '#ac0f0f',
            name: 'quote'
          }),
          styles.h
        ])}>
        {title}
      </h2>
      <blockquote
        className={css([
          unstyle.blockquote,
          styles.blockquote
        ])}>
        <p
          className={css([
            unstyle.p,
            styles.p
          ])}>
          {review}
        </p>
        <cite
          className={css([
            unstyle.cite,
            styles.cite
          ])}>
          {author}
        </cite>
      </blockquote>
    </Element>
  );
};

RegionTestimonials.defaultProps = {
  as: 'div',
  style: {}
};

RegionTestimonials.displayName = 'RegionTestimonials';

RegionTestimonials.propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  style: PropTypes.object
};

export default RegionTestimonials;
