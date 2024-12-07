import * as React from 'react';

import AgeTermsWarning from '../index';

describe('AgeTermsWarning', () => {
  it('renders', () => {
    expect(
      render(
        <AgeTermsWarning />
      )
    ).toMatchSnapshot();
  });
});
