
import React from 'react';

import MBDrawer from '../MBDrawer';

describe('MBDrawer', () => {
  it('renders', () => {
    expect(render(
      <MBDrawer open>
        <div>Fun!</div>
      </MBDrawer>
    )).toMatchSnapshot();
  });

  it('renders hidden state', () => {
    expect(render(
      <MBDrawer open={false}>
        <div>Fun!</div>
      </MBDrawer>
    )).toMatchSnapshot();
  });
});
