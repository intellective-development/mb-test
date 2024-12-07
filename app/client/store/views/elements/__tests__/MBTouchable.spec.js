
import * as React from 'react';

import MBTouchable from '../MBTouchable';

describe('MBTouchable', () => {
  it('renders', () => {
    expect(shallow(
      <MBTouchable>Click it.</MBTouchable>
    )).toMatchSnapshot();
  });
});
