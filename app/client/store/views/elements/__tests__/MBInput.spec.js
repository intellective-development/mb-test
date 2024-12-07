
import * as React from 'react';

// import TestProvider from 'client/store/__tests__/utils/TestProvider';
import * as MBInput from '../MBInput';

describe('MBInput.Input', () => {
  it('renders', () => {
    expect(shallow(<MBInput.Input />)).toMatchSnapshot();
  });
});
