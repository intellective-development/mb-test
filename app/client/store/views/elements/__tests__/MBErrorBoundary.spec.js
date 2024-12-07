import * as React from 'react';
import MBErrorBoundary from '../MBErrorBoundary';

describe('MBErrorBoundary', () => {
  it('renders', () => {
    expect(render(
      <MBErrorBoundary errorMessage={() => 'Some message'}>
        <div>A thing to click outside of</div>
      </MBErrorBoundary>
    )).toMatchSnapshot();
  });
});
