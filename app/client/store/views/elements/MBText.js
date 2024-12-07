// @flow

import * as React from 'react';
import bindClassNames from '../../../shared/utils/bind_classnames';
import styles from './MBText.scss';

const cn = bindClassNames(styles);

// This module exports a set of wrappers around the basic react text elements
// The idea is to provide a new baseline for us to work off of as we move towards component style sharing.
// Eventually, the goal is to fit these components and props into the styleguide the design team is working towards.

type MBTextProps = { className?: string, reset_spacing?: boolean };

type TextTag = 'p' | 'a' | 'span' | 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6'; // these are the JSX intrinsics (strings). see React.ElementType
export const makeMBText = (TextTagComponent: TextTag, OverrideComponent?: React.ComponentType<*>) => {
  // we use the override component if provided, otherwise we fall back to letting jsx use the built in component that matches the tag string
  const TextComponent = OverrideComponent || TextTagComponent;

  const MBText = ({className, reset_spacing = true, ...rest_props}: MBTextProps) => {
    const classes = cn('elMBText', {elMBText_ResetSpacing: reset_spacing}, className);
    return <TextComponent {...rest_props} className={classes} />;
  };
  MBText.displayName = `MBText(${TextTagComponent})`;

  return MBText;
};

export const Span = makeMBText('span');
export const H1 = makeMBText('h1');
export const H2 = makeMBText('h2');
export const H3 = makeMBText('h3');
export const H4 = makeMBText('h4');
export const H5 = makeMBText('h5');
export const H6 = makeMBText('h6');

// the p component has custom props, used in conjunction with those provided by makeMBText
type PProps = { className: string, body_copy?: boolean };
export const P = makeMBText('p', (({className, body_copy, ...rest_props}: PProps) => {
  const classes = cn('elMBText_P', {elMBText_P__BodyCopy: body_copy}, className);

  return <p {...rest_props} className={classes} />;
}));

// the a component has custom styles, used in conjunction with those provided by makeMBText
type AProps = { className: string, standard?: boolean, body_copy?: boolean };
export const A = makeMBText('a', (({className, standard = true, ...rest_props}: AProps) => {
  const classes = cn('elMBText_A', {elMBText_A__Standard: standard}, className);

  return <a {...rest_props} className={classes} />;
}));
