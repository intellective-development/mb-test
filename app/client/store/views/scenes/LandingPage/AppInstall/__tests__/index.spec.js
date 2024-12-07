import * as React from 'react';
import AppInstallSection from '../index';

describe('AppInstallSection', () => {
  it('renders', () => {
    expect(
      render(<AppInstallSection />)
    ).toMatchSnapshot();
  });
});
