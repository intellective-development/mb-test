
import * as React from 'react';

// import TestProvider from 'client/store/__tests__/utils/TestProvider';
import MBButton from '../MBButton';
import * as MBInput from '../MBInput';
import * as MBLayout from '../MBLayout';

describe('MBLayout.ButtonInput', () => {
  it('renders', () => {
    expect(render(
      <MBLayout.ButtonInput>
        <MBInput.Input />
        <MBButton size="small">Go</MBButton>
      </MBLayout.ButtonInput>
    )).toMatchSnapshot();
  });
});

describe('MBLayout.ButtonGroup', () => {
  it('renders', () => {
    expect(render(
      <MBLayout.ButtonGroup>
        <MBButton size="small">Confirm</MBButton>
        <MBButton size="small">Deny</MBButton>
      </MBLayout.ButtonGroup>
    )).toMatchSnapshot();
  });
});
