
import React from 'react';
import address_factory from 'store/business/address/__tests__/address.factory';
import delivery_method_factory from 'store/business/delivery_method/__tests__/delivery_method.factory';
import supplier_factory from 'store/business/supplier/__tests__/supplier.factory';
import { LOADING_STATUS } from '@minibar/store-business/src/utils/fetch_status';

import TestProvider from 'store/views/__tests__/utils/TestProvider';
import DeliveryInfo, { __private__ } from '../DeliveryInfo';

const { deliveryMessage } = __private__;

describe('DeliveryInfo', () => {
  it('renders', () => {
    const initial_state = {
      ...supplier_factory.stateify([
        supplier_factory.build('with_delivery_methods')
      ]),
      ...address_factory.stateify(
        address_factory.build()
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <DeliveryInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders with different delivery method types', () => {
    const initial_state = {
      ...supplier_factory.stateify([
        supplier_factory.build({delivery_methods: [delivery_method_factory.build('shipped')]}),
        supplier_factory.build({delivery_methods: [delivery_method_factory.build('pickup')]})
      ]),
      ...address_factory.stateify(
        address_factory.build()
      )
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <DeliveryInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders with an address missing', () => {
    const initial_state = {
      ...supplier_factory.stateify([
        supplier_factory.build('with_delivery_methods')
      ])
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <DeliveryInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });

  it('renders with an address loading', () => {
    const initial_state = {
      ...supplier_factory.stateify([
        supplier_factory.build('with_delivery_methods')
      ]),
      address: {
        fetch_status: LOADING_STATUS
      }
    };

    expect(render(
      <TestProvider initial_state={initial_state}>
        <DeliveryInfo />
      </TestProvider>
    )).toMatchSnapshot();
  });
});

describe('deliveryMessage', () => {
  it('returns a message for on_demand types', () => {
    expect(deliveryMessage(['on_demand'])).toEqual('Delivery to');
  });

  it('returns a message for pickup types', () => {
    expect(deliveryMessage(['pickup'])).toEqual('In-Store pickup near');
  });

  it('returns a message for shipped types', () => {
    expect(deliveryMessage(['shipped'])).toEqual('Shipping to');
  });

  it('returns a message for on_demand and pickup types', () => {
    expect(deliveryMessage(['on_demand', 'pickup'])).toEqual('Delivery and in-store pickup');
  });

  it('returns a message for on_demand and shipped types', () => {
    expect(deliveryMessage(['on_demand', 'shipped'])).toEqual('Delivery and shipping');
  });

  it('returns a message for on_demand pickup and shipped types', () => {
    expect(deliveryMessage(['pickup', 'shipped'])).toEqual('In-store pickup and shipping');
  });

  it('ignores initial ordering', () => {
    expect(deliveryMessage(['shipped', 'pickup'])).toEqual('In-store pickup and shipping');
  });

  it('ignores repeats when the types are homogenous', () => {
    expect(deliveryMessage(['on_demand', 'on_demand'])).toEqual('Delivery to');
  });

  it('ignores repeats when the types are not homogenous', () => {
    expect(deliveryMessage(['on_demand', 'shipped', 'on_demand'])).toEqual('Delivery and shipping');
  });
});
