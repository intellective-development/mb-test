// @flow
import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';

import styles from './MBInput.scss';

const cn = bindClassNames(styles);

// This module exports a wrapper around the basic html input element.
// The idea is to provide a new baseline for us to work off of as we move towards component style sharing.
// Eventually, the goal is to fit this component and its props into the styleguide the design team is working towards.

type MBInputProps = {className: string, inputRef: Function} & React.DetailedHTMLProps<React.InputHTMLAttributes<HTMLInputElement>>;
export const Input = ({className, inputRef, ...input_props}: MBInputProps) => {
  const classes = cn('elMBInput', className);
  return <input {...input_props} className={classes} ref={inputRef} />;
};
