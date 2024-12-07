import * as React from 'react';
import MBClickOutside from '../MBClickOutside';

describe('MBClickOutside', () => {
  it('renders', () => {
    expect(render(
      <MBClickOutside handleClickOutside={() => {}}>
        <div>A thing to click outside of</div>
      </MBClickOutside>
    )).toMatchSnapshot();
  });
});
