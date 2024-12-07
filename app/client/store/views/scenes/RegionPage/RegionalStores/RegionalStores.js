import { create, css } from '@amory/style/umd/style';
import { get, size } from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';

import { useToggle } from '../../ProductList/hooks/use-toggle';
import { fonts, unstyle } from '../../../style/index';

import { LiquorStore } from '../LiquorStore/index';

import styles from './RegionalStores.css.json';

export const RegionalStores = ({
  as: Element,
  className,
  suppliers,
  region,
  style,
  ...props
}) => {
  const [toggle, setToggle] = useToggle(false);
  const title = ['Stores in', get(region, 'name')].join(' ');

  create(fonts);

  return (
    <Element
      className={css([
        styles.section,
        style
      ], className)}
      {...props}>
      <h2
        className={css([
          unstyle.h,
          fonts.common,
          styles.title
        ])}>
        {title}
      </h2>
      <div
        className={css([
          fonts.common,
          styles.stores
        ])}>
        {suppliers.map(({
          address,
          display_name,
          id,
          permalink,
          profile
        }, i) =>
          (i < 8 || toggle
            ? (
              <LiquorStore
                address={address}
                display_name={display_name}
                key={id}
                permalink={permalink}
                profile={profile}
                region={region} />
            )
            : null
          ))}
      </div>
      {size(suppliers) < 8 || toggle
        ? null
        : (
          <button
            className={css([
              unstyle.button,
              fonts.common,
              styles.button
            ])}
            onClick={setToggle}
            type="button">
            See all
          </button>
        )}
    </Element>
  );
};

RegionalStores.defaultProps = {
  as: 'div',
  style: {}
};

RegionalStores.displayName = 'RegionalStores';

RegionalStores.propTypes = {
  as: PropTypes.elementType,
  className: PropTypes.string,
  suppliers: PropTypes.array,
  region: PropTypes.object,
  style: PropTypes.object
};

export default RegionalStores;
