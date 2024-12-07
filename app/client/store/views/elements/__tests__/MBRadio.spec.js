
import * as React from 'react';

import MBRadio from '../MBRadio';

describe('MBRadio', () => {
  it('renders', () => {
    expect(shallow(
      <MBRadio />
    )).toMatchSnapshot();
  });

  it('renders an active button', () => {
    expect(shallow(
      <MBRadio active />
    )).toMatchSnapshot();
  });
});
