/* eslint import/first: 0 */

jest.mock('client/shared/components/higher_order/make_provided'); // avoid importing the full store
jest.mock('legacy_store/models/Cart');

import * as React from 'react';

import { CurrentDeliveryInfoModal } from '../index';

describe('CurrentDeliveryInfoModal', () => {
  it('renders the current_delivery_info view', () => {
    expect(shallow(
      <CurrentDeliveryInfoModal />
    )).toMatchSnapshot();
  });

  it('renders the supplier switching view after routing to it', () => {
    const component = shallow(<CurrentDeliveryInfoModal />);

    // switch to the supplier switching view
    component.instance().deliveryInfoRouteTo('supplier_switching', {supplier_id: 1});
    component.update();

    expect(component).toMatchSnapshot();
  });

  it('renders the waitlist view after routing to it', () => {
    const component = shallow(<CurrentDeliveryInfoModal />);

    // switch to the waitlist view
    component.instance().deliveryInfoRouteTo('address_waitlist', {supplier_id: 1});
    component.update();

    expect(component).toMatchSnapshot();
  });

  it('renders nothing when hidden', () => {
    expect(shallow(
      <CurrentDeliveryInfoModal is_hidden />
    )).toMatchSnapshot();
  });
});
