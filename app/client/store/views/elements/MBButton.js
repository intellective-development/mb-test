// @flow

import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';

import styles from './MBButton.scss';

const cn = bindClassNames(styles);

// This module exports a wrapper around the basic html button element.
// The idea is to provide a new baseline for us to work off of as we move towards component style sharing.
// Eventually, the goal is to fit this component and its props into the styleguide the design team is working towards.

type MBButtonProps = {
  className?: string,
  type?: 'default' | 'hollow' | 'action',
  size?: 'medium' | 'small' | 'tall', // TODO: transition to a boolean, small or not small
  expand?: boolean
};

const MBButton = ({className, type = 'default', size = 'medium', expand = false, ...rest_props}: MBButtonProps) => {
  const classes = cn('elMBButton', {
    // types
    elMBButton__Default: type === 'default',
    elMBButton__Hollow: type === 'hollow',
    elMBButton__Action: type === 'action',

    // sizes
    elMBButton__Medium: size === 'medium',
    elMBButton__Small: size === 'small',
    elMBButton__Tall: size === 'tall',

    elMBButton__Expand: expand
  }, className);

  return <button {...rest_props} className={classes} />;
};

export default MBButton;
