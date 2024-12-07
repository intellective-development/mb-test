
import React from 'react';

import MBLoader from '../MBLoader';

describe('MBLoader', () => {
  it('renders', () => {
    expect(render(
      <MBLoader />
    )).toMatchSnapshot();
  });
});
