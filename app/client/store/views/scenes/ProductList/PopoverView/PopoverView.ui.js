import React, { Fragment } from 'react';
import { storiesOf } from '@storybook/react';
import { useBounds } from '../hooks/use-bounds';
import { useToggle } from '../hooks/use-toggle';
import { PopoverView } from './PopoverView';

const lipsum = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

const TestView = ({
  position,
  ...props
}) => {
  const { bottom, left, ref, width } = useBounds();
  const [toggle, setToggle] = useToggle(false);

  return (
    <Fragment>
      <div
        style={{
          'text-align': position
        }}>
        <button
          onClick={() => setToggle()}
          ref={ref}
          type="button">
          PopoverView
        </button>
      </div>
      <PopoverView
        {...props}
        onClick={() => setToggle()}
        position={position}
        toggle={toggle}
        toggleBottom={bottom}
        toggleLeft={left}
        toggleWidth={width} />
    </Fragment>
  );
};

TestView.defaultProps = PopoverView.defaultProps;

TestView.displayName = 'PopoverView';

TestView.propTypes = PopoverView.propTypes;

storiesOf('ProductList/PopoverView', module)
  .add('left', () => (
    <TestView
      position="left">
      <div>
        {lipsum}
        {lipsum}
        {lipsum}
        {lipsum}
      </div>
    </TestView>
  ))
  .add('center', () => (
    <TestView
      position="center">
      <div>
        {lipsum}
        {lipsum}
        {lipsum}
        {lipsum}
      </div>
    </TestView>
  ))
  .add('right', () => (
    <TestView
      position="right">
      <div>
        {lipsum}
        {lipsum}
        {lipsum}
        {lipsum}
      </div>
    </TestView>
  ));
