
import React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import ContactUs from '../ContactUs';

describe('ContactUs', () => {
  it.skip('renders', () => {
    // TODO: test in the branch the contains the actual implementation

    const initial_state = {
      ui: {
        show_help_modal: true
      }
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <ContactUs />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
