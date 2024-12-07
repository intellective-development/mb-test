import { create, css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React, { Fragment } from 'react';

import { getRegionFAQContent } from './RegionFAQContent';
import { fonts, unstyle } from '../../../style/index';

import styles from './RegionFaq.css.json';

export const RegionFaq = ({
  'as': Element,
  className,
  style,
  region = {},
  ...props
}) => {
  create(fonts);

  return (
    <Element className={css([fonts.common, style], className)} {...props}>
      <h2 className={css([unstyle.h, styles.title])}>
              Frequently Asked Questions About Alcohol Delivery in { region.name }
      </h2>
      <div className={css(styles.section)}>
        {getRegionFAQContent(region).map(({ answer, question }) =>
          (
            <Fragment
              key={question}>
              <h3
                className={css([
                  unstyle.h,
                  styles.question
                ])}>
                {question}
              </h3>
              <p
                className={css([
                  unstyle.p,
                  styles.answer
                ])}>
                {answer}
              </p>
            </Fragment>
          ))}
      </div>
    </Element>
  );
};

RegionFaq.defaultProps = {
  as: 'div',
  style: {}
};

RegionFaq.displayName = 'RegionFaq';

RegionFaq.propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  style: PropTypes.object
};

export default RegionFaq;
