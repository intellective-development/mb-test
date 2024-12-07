import * as React from 'react';
import { CSSTransition } from 'react-transition-group';
import classNames from 'classnames';
import { MBTouchable } from '../store/views/elements';

// This module contains a collection of helpers that are shared between the two content placements.
// I did not want to force the two of them to share the same AddonItem component, and also did not want
// To impose any restrictions on the component hierarchy.

export const CartPlacementTransitioner = ({ children = [], className }) => (
  <CSSTransition
    classNames="transition-"
    timeout={{ enter: 300, exit: 300}}
    component="ul"
    className={classNames('grid-product__container', 'grid-product__container--cart', className)} >
    <React.Fragment>
      {children}
    </React.Fragment>
  </CSSTransition>
);

export const SmallAddToCartButton = ({ buttonLifecycleState, disabled }) => {
  const button_content = (buttonLifecycleState === 'added') ? '✓' : '+';

  return (
    <MBTouchable disabled={disabled} className="button hollow add-to-cart add-to-cart--small">
      {button_content}
    </MBTouchable>
  );
};
