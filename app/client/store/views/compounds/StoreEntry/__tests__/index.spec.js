/* eslint import/first: 0 */
jest.mock('shared/components/higher_order/make_provided'); // avoid importing the full store

import * as React from 'react';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import StoreEntry from '../index';

describe('StoreEntry', () => {
  it('renders', () => {
    expect(render(
      <TestProvider>
        <StoreEntry />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
