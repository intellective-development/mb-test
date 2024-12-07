
import * as React from 'react';

import MBGrid from '../MBGrid';

describe('MBGrid', () => {
  it('renders', () => {
    expect(shallow(<MBGrid />)).toMatchSnapshot();
  });
});
