import React, { forwardRef } from 'react';
import { CSSTransition } from 'react-transition-group';
import PropTypes from 'prop-types';
import './AnimateView.scss';

export const AnimateView = forwardRef(
  ({ children, classNames, toggle, ...props }, ref) => (
    <CSSTransition
      classNames={classNames}
      in={toggle}
      timeout={300}
      unmountOnExit>
      <div
        {...props}
        ref={ref}>
        {children}
      </div>
    </CSSTransition>
  )
);

AnimateView.defaultProps = {
  children: null,
  classNames: '',
  toggle: false
};

AnimateView.displayName = 'AnimateView';

AnimateView.propTypes = {
  children: PropTypes.node,
  classNames: PropTypes.string,
  toggle: PropTypes.bool
};
