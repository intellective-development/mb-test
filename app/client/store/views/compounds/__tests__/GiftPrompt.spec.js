
import * as React from 'react';

// import TestProvider from 'client/store/__tests__/utils/TestProvider';
import GiftPrompt from '../GiftPrompt';

describe('GiftPrompt', () => {
  it('renders', () => {
    expect(render(<GiftPrompt />)).toMatchSnapshot();
  });
});
