import * as React from 'react';
import MBDynamicIcon from '../index';

describe('MBDynamicIcon', () => {
  it('renders', () => {
    expect(shallow(<MBDynamicIcon name="email" width={25} height={25} color="mb_white" />)).toMatchSnapshot();
  });
});
