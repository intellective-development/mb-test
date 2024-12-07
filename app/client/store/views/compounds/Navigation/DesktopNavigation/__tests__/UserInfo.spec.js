
import React from 'react';
import user_factory from 'store/business/user/__tests__/user.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import UserInfo from '../UserInfo';

describe('UserInfo', () => {
  it('renders with user', () => {
    const initial_state = {
      ...user_factory.stateify(
        user_factory.build({id: 1})
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <UserInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders user fetching state', () => {
    const initial_state = {
      user: {
        is_fetching: true
      }
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <UserInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders without user', () => {
    const initial_state = {};

    expect(render(
      <TestProvider initial_state={initial_state}>
        <UserInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
