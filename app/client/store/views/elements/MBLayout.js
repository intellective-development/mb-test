// @flow

import * as React from 'react';
import cn from 'classnames';

// This module exports a set of small layouts we use in multiple places in the app. At the moment, it's a bit of a catch all
// The idea is to provide a new baseline for us to work off of as we move towards component style sharing.
// Eventually, the goal is to fit this component and its props into the styleguide the design team is working towards.

type ButtonInputProps = {className?: string, children?: React.Node};
export const ButtonInput = ({className, children}: ButtonInputProps) => {
  const classes = cn('el-mblayouts-bi__container', className);
  return (
    <div className={classes}>
      {children}
    </div>
  );
};

type ButtonGroupProps = {className?: string, children?: React.Node};
export const ButtonGroup = ({className, children}: ButtonGroupProps) => {
  const classes = cn('el-mblayouts-bg__container', className);
  return (
    <div className={classes}>
      {children}
    </div>
  );
};

type StandardGridProps = {className?: string, no_padding?: boolean, children?: React.Node};
export const StandardGrid = ({className, no_padding, children, ...rest_props}: StandardGridProps) => {
  const classes = cn('el-mblayouts-sg', {_pad_sides: !no_padding}, className);

  return (
    <div {...rest_props} className={classes}>
      {children}
    </div>
  );
};
