import { create, css } from '@amory/style/umd/style';
import PropTypes from 'prop-types';
import React, { Fragment } from 'react';

import { common, fonts, unstyle } from '../../../style/index';
import icon from '../../../../business/checkout/shared/MBIcon/MBIcon';

import styles from './HowItWorks.css.json';

export const HowItWorks = ({
  'as': Element,
  className,
  style,
  ...props
}) => {
  create(fonts);

  const panels = [
    [
      'mapPin',
      'Enter Your Address',
      [
        'Once you tell us your location, we’ll show you what’s available',
        'to you today from our local store partners.'
      ].join(' ')
    ],
    [
      'shop',
      'Shop',
      [
        'Browse from thousands of new, local, well-known items from wine,',
        'beer and spirits to mixers, flowers and more. Select your',
        'favorites, add to cart and easily checkout on our website or app.'
      ].join(' ')
    ],
    [
      'enjoy',
      'Enjoy',
      [
        'Sit back and relax. Your order will be delivered to your door in as',
        'little as 30-60 minutes. Cheers!'
      ].join(' ')
    ]
  ];

  return (
    <Fragment>
      <Element
        className={css([
          styles.section,
          style
        ], className)}
        {...props}>
        <h2
          className={css([
            unstyle.h,
            fonts.headline,
            styles.h2
          ])}>
          How Minibar Delivery works.
        </h2>
        <div
          className={css(styles.div)}>
          {panels.map(([name, head, text]) =>
            (
              <div
                className={css([
                  fonts.common,
                  styles.panel
                ])}
                key={name}>
                <h3
                  className={css([
                    unstyle.h,
                    styles.h3,
                    icon({ color: '#222', name, variant: 2 })
                  ])}>
                  {head}
                </h3>
                <p
                  className={css([
                    unstyle.p,
                    styles.p
                  ])}>
                  {text}
                </p>
              </div>
            ))}
        </div>
      </Element>
      <hr
        className={css([
          unstyle.hr,
          common.hr,
          styles.hr
        ])} />
    </Fragment>
  );
};

HowItWorks.defaultProps = {
  as: 'div',
  style: {}
};

HowItWorks.displayName = 'HowItWorks';

HowItWorks.propTypes = {
  as: PropTypes.elementType,
  children: PropTypes.node,
  className: PropTypes.string,
  style: PropTypes.object
};

export default HowItWorks;
