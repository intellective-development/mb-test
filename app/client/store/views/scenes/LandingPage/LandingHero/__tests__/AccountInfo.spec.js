import * as React from 'react';
import user_factory from 'store/business/user/__tests__/user.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import AccountInfo from '../AccountInfo';

describe('AccountInfo', () => {
  it('renders with user', () => {
    const initial_state = {
      user: {
        ...user_factory.stateify(user_factory.build()).user,
        is_fetching: false
      }
    };

    expect(
      render(
        <TestProvider initial_state={initial_state}>
          <AccountInfo />
        </TestProvider>
      )
    ).toMatchSnapshot();
  });

  it('renders fetching user', () => {
    const initial_state = {user: {is_fetching: true}};

    expect(
      render(
        <TestProvider initial_state={initial_state}>
          <AccountInfo />
        </TestProvider>
      )
    ).toMatchSnapshot();
  });

  it('renders logged out user', () => {
    const initial_state = {user: {is_fetching: false}};

    expect(
      render(
        <TestProvider initial_state={initial_state}>
          <AccountInfo />
        </TestProvider>
      )
    ).toMatchSnapshot();
  });
});
