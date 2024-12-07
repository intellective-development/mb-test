
import * as React from 'react';

// import TestProvider from 'client/store/__tests__/utils/TestProvider';
import MBIcon from '../MBIcon';

describe('MBIcon', () => {
  it('renders', () => {
    expect(shallow(<MBIcon name="back" />)).toMatchSnapshot();
  });

  it('renders a namespaced icon', () => {
    expect(shallow(<MBIcon name="mobile.minibar_logo" />)).toMatchSnapshot();
  });
});
