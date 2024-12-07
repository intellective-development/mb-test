
import * as React from 'react';
import MBImageGrid from '../MBImageGrid';

describe('MBImageGrid', () => {
  it('renders', () => {
    expect(shallow(<MBImageGrid title="foo" action_url="foo" content={[]} />)).toMatchSnapshot();
  });
});
