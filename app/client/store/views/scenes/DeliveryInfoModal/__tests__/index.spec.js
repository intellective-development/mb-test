import React from 'react';

import { __private__ } from '../index';

jest.mock('client/shared/components/higher_order/make_provided'); // avoid importing the full store
jest.mock('legacy_store/models/Cart');

const { DeliveryInfoModal } = __private__;

describe('DeliveryInfoModal', () => {
  afterEach(() => {
    delete global.Minibar;
  });

  it('renders current delivery info when inside the store with an address present', () => {
    global.Minibar = {};

    expect(shallow(
      <DeliveryInfoModal is_hidden={false} has_delivery_address />
    )).toMatchSnapshot();
  });

  it('renders address entry when we dont have an address but are inside the store', () => {
    global.Minibar = {};

    expect(shallow(
      <DeliveryInfoModal is_hidden={false} has_delivery_address={false} />
    )).toMatchSnapshot();
  });

  it('renders address entry when we have an address but are not inside the store', () => {
    global.Minibar = undefined;

    expect(shallow(
      <DeliveryInfoModal is_hidden={false} has_delivery_address />
    )).toMatchSnapshot();
  });

  it('renders address entry when we dont have an address and are not inside the store', () => {
    global.Minibar = undefined;

    expect(shallow(
      <DeliveryInfoModal is_hidden={false} has_delivery_address={false} />
    )).toMatchSnapshot();
  });

  describe('is_hidden', () => {
    it('renders, respecting is_hidden when it would render current delivery info', () => {
      global.Minibar = {};

      expect(shallow(
        <DeliveryInfoModal is_hidden has_delivery_address />
      )).toMatchSnapshot();
    });

    it('renders, respecting is_hidden when it would render address entry', () => {
      global.Minibar = undefined;

      expect(shallow(
        <DeliveryInfoModal is_hidden has_delivery_address={false} />
      )).toMatchSnapshot();
    });
  });
});
