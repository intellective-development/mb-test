import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import AddressDropdown from '../AddressDropdown';

describe('AddressDropdown', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <AddressDropdown
          recent_addresses={[]}
          google_addresses={[]}
          input_address=""
          visible
          selected_index={0}
          submitOption={() => {}} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
