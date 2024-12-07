import React, { Fragment } from 'react';
import { createPortal } from 'react-dom';
import PropTypes from 'prop-types';
import { AnimateView } from '../AnimateView/AnimateView';
import { useBounds } from '../hooks/use-bounds';
import { PopoverArrow } from './PopoverArrow';
import './PopoverView.scss';

export const PopoverView = ({
  children,
  className,
  classNames,
  position,
  toggleBottom,
  toggleLeft,
  toggleWidth,
  ...props
}) => {
  const { left, ref } = useBounds();

  return (
    <Fragment>
      {createPortal(
        <Fragment>
          <AnimateView
            {...props}
            className="modal-backdrop"
            classNames={classNames} />
          <AnimateView
            {...props}
            className={[className, [className, position].join('-')].join(' ')}
            classNames={classNames}>
            <div
              onClick={(e) => e.stopPropagation()}
              ref={ref}
              role="presentation"
              style={{
                top: `${toggleBottom}px`
              }}>
              <PopoverArrow
                popoverLeft={left}
                toggleLeft={toggleLeft}
                toggleWidth={toggleWidth} />
              <div>
                {children}
              </div>
            </div>
          </AnimateView>
        </Fragment>,
        document.body
      )}
    </Fragment>
  );
};

PopoverView.defaultProps = {
  children: null,
  className: 'popover-view',
  classNames: 'fade',
  position: 'right',
  toggleBottom: 0,
  toggleLeft: 0,
  toggleWidth: 0
};

PopoverView.displayName = 'PopoverView';

PopoverView.propTypes = {
  children: PropTypes.node,
  className: PropTypes.string,
  classNames: PropTypes.string,
  position: PropTypes.oneOf([
    'center',
    'left',
    'right'
  ]),
  toggleBottom: PropTypes.number,
  toggleLeft: PropTypes.number,
  toggleWidth: PropTypes.number
};
