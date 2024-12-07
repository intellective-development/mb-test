import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import LandingHero from '../index';

describe('LandingHero', () => {
  it('renders', () => {
    expect(
      render(
        <TestProvider>
          <LandingHero />
        </TestProvider>
      )
    ).toMatchSnapshot();
  });
});
