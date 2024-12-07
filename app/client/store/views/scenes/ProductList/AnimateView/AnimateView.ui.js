import React, { Fragment } from 'react';
import { storiesOf } from '@storybook/react';
import { useToggle } from '../hooks/use-toggle';
import { AnimateView } from './AnimateView';

const lipsum = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

const TestView = (props) => {
  const { classNames } = props;
  const [toggle, setToggle] = useToggle(false);

  return (
    <Fragment>
      <button
        onClick={() => setToggle()}
        type="button">
        {classNames}
      </button>
      <AnimateView
        {...props}
        onClick={() => setToggle()}
        toggle={toggle} />
    </Fragment>
  );
};

TestView.defaultProps = AnimateView.defaultProps;

TestView.displayName = 'AnimateView';

TestView.propTypes = AnimateView.propTypes;

storiesOf('ProductList/AnimateView', module)
  .add('fade', () => (
    <TestView
      classNames="fade">
      {lipsum}
    </TestView>
  ))
  .add('slide-down', () => (
    <TestView
      classNames="slide-down">
      {lipsum}
    </TestView>
  ))
  .add('slide-left', () => (
    <TestView
      classNames="slide-left">
      {lipsum}
    </TestView>
  ))
  .add('slide-right', () => (
    <TestView
      classNames="slide-right">
      {lipsum}
    </TestView>
  ))
  .add('slide-up', () => (
    <TestView
      classNames="slide-up">
      {lipsum}
    </TestView>
  ));
