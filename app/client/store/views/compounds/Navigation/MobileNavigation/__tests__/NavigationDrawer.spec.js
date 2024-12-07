
import React from 'react';
import address_factory from 'store/business/address/__tests__/address.factory';
import user_factory from 'store/business/user/__tests__/user.factory';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import NavigationDrawer from '../NavigationDrawer';

describe('NavigationDrawer', () => {
  it('renders', () => {
    const initial_state = {
      ...address_factory.stateify(
        address_factory.build({local_id: '10'})
      ),
      ...user_factory.stateify(
        user_factory.build({id: 1})
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <NavigationDrawer show />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders without user', () => {
    const initial_state = {
      ...address_factory.stateify(
        address_factory.build({local_id: '10'})
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <NavigationDrawer show />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders without address', () => {
    const initial_state = {
      ...user_factory.stateify(
        user_factory.build({id: 1})
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <NavigationDrawer show />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders a closed state', () => {
    expect(render(
      <TestProvider>
        <NavigationDrawer show={false} />
      </TestProvider>
    )).toMatchSnapshot();
  });
});
