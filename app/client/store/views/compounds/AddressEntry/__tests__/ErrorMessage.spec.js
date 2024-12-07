import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import ErrorMessage from '../ErrorMessage';

describe('ErrorMessage', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <ErrorMessage message_type="no_address" />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
