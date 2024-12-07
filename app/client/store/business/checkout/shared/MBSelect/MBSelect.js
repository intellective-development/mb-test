import { css } from '@amory/style/umd/style';
import React from 'react';
import icon from '../MBIcon/MBIcon';
import unstyle from '../MBElements/MBUnstyle.css.json';
import styles from './MBSelect.css.json';

const MBSelect = ({
  children,
  id,
  style = {},
  input,
  ...props
}) => (
  <select
    {...input}
    className={css([
      unstyle.select,
      style,
      {
        backgroundImage: [
          icon({
            color: '#757575',
            name: 'arrowDown'
          })['::before'].backgroundImage
        ]
      },
      styles.select,
      style.paddingLeft ? { paddingLeft: style.paddingLeft } : {}
    ])}
    id={id}
    {...props}>
    {children}
  </select>
);

MBSelect.displayName = 'MBSelect';

export default MBSelect;
