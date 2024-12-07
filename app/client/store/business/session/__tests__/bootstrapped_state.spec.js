/* eslint import/first: 0 */
jest.mock('../../utils/mb_cookie');

import _ from 'lodash';
import { createStore } from 'redux';
import * as mb_cookie from '../../utils/mb_cookie';
import baseReducer from '../../base_reducer';
import user_factory from '../../user/__tests__/user.factory';
import address_factory from '../../address/__tests__/address.factory';
import pp_factory from '../../payment_profile/__tests__/payment_profile.factory';
import getBootstrappedState, { __private__ } from '../bootstrapped_state';

const { formatDeliveryAddressState, formatUserState, formatEmailCaptureModalState, formatCartIdState } = __private__;


describe('formatDeliveryAddressState', () => {
  it('formats delivery address data', () => {
    const current_address = address_factory.build({local_id: 30});
    expect(formatDeliveryAddressState(current_address)).toEqual({
      address: {
        by_id: {
          [current_address.local_id]: current_address
        },
        current_delivery_address_id: current_address.local_id
      }
    });
  });
});

describe('formatEmailCaptureModalState', () => {
  it('hides the modal if a user exists', () => {
    const user = user_factory.build();
    const user_has_seen_modal = false;
    const user_is_on_mobile = false;
    expect(formatEmailCaptureModalState(user, user_has_seen_modal, user_is_on_mobile)).toEqual({
      email_capture: { should_show_modal: false }
    });
  });
  it('hides if the email_capture_modal_seen cookie returns true', () => {
    const user = {};
    const user_has_seen_modal = true;
    const user_is_on_mobile = false;
    expect(formatEmailCaptureModalState(user, user_has_seen_modal, user_is_on_mobile)).toEqual({
      email_capture: { should_show_modal: false }
    });
  });
  it('hides if the user is on mobile', () => {
    const user = {};
    const user_has_seen_modal = false;
    const user_is_on_mobile = true;
    expect(formatEmailCaptureModalState(user, user_has_seen_modal, user_is_on_mobile)).toEqual({
      email_capture: { should_show_modal: false }
    });
  });
  it('shows the modal if no user exists and email_capture_modal_seen cookie doesnt exist and UA isnt mobile', () => {
    const user = {};
    const user_has_seen_modal = false;
    const user_is_on_mobile = false;
    expect(formatEmailCaptureModalState(user, user_has_seen_modal, user_is_on_mobile)).toEqual({
      email_capture: { should_show_modal: true }
    });
  });
});

describe('formatUserState', () => {
  it('generates a state object for a non-normalized user', () => {
    const shipping_addresses = [
      address_factory.build({local_id: 10, local_type: 'user_shipping'}),
      address_factory.build({local_id: 20, local_type: 'user_shipping'})
    ];
    const payment_profiles = [pp_factory.build({id: 100}), pp_factory.build({id: 200})];
    const user = user_factory.build({
      id: 1,
      shipping_addresses,
      payment_profiles
    });

    expect(formatUserState(user)).toEqual({
      address: {
        by_id: {10: shipping_addresses[0], 20: shipping_addresses[1]}
      },
      payment_profile: {
        by_id: {100: payment_profiles[0], 200: payment_profiles[1]},
        user_payment_profile_ids: [100, 200]
      },
      user: {
        by_id: {1: {
          ...(_.omit(user, 'payment_profiles')),
          shipping_addresses: [10, 20]
        }},
        current_user_id: 1
      }
    });
  });
});

describe('formatCartIdState', () => {
  it('generates a state object for a cart_id', () => {
    const cart_id = 1;
    expect(formatCartIdState(cart_id)).toEqual({
      cart_item: {
        cart_id: 1
      }
    });
  });
});

describe('getBootstrappedState', () => {
  let user;
  let shipping_addresses;
  let current_address;
  let payment_profiles;

  beforeEach(() => {
    shipping_addresses = [
      address_factory.build({local_id: 10, local_type: 'user_shipping'}),
      address_factory.build({local_id: 20, local_type: 'user_shipping'})
    ];
    current_address = address_factory.build({local_id: 30});
    payment_profiles = [pp_factory.build({id: 100}), pp_factory.build({id: 200})];

    user = user_factory.build({
      id: 1,
      shipping_addresses,
      payment_profiles
    });
  });

  afterEach(() => {
    // clear out the values we've been setting
    delete global.Data;
    delete global.Entry;
  });

  it('combines the states', () => {
    global.Data = { user: user, cart_id: 1 };

    mb_cookie.get.mockReturnValueOnce(true);
    mb_cookie.get.mockReturnValueOnce(current_address);

    expect(getBootstrappedState()).toEqual({
      address: {
        by_id: {
          10: shipping_addresses[0],
          20: shipping_addresses[1],
          30: current_address
        },
        current_delivery_address_id: 30
      },
      email_capture: {
        should_show_modal: false
      },
      payment_profile: {
        by_id: {100: payment_profiles[0], 200: payment_profiles[1]},
        user_payment_profile_ids: [100, 200]
      },
      user: {
        by_id: {1: {
          ...(_.omit(user, 'payment_profiles')),
          shipping_addresses: [10, 20]
        }},
        current_user_id: 1
      },
      cart_item: {
        cart_id: 1
      }
    });
  });

  it('combines the states with initial_state if provided', () => {
    global.Data = { user: user, cart_id: 1 };

    mb_cookie.get.mockReturnValueOnce('email_capture_modal_check_skip');
    mb_cookie.get.mockReturnValueOnce(current_address);

    const old_current_address = address_factory.build({local_id: current_address.local_id, address1: 'foo'});
    const other_shipping_addresses = [
      address_factory.build({local_id: 40}),
      address_factory.build({local_id: 50})
    ];

    const other_inital_state = {
      address: {
        by_id: {
          [old_current_address.local_id]: old_current_address,
          40: other_shipping_addresses[0],
          50: other_shipping_addresses[1]
        }
      }
    };

    expect(getBootstrappedState(other_inital_state)).toEqual({
      address: {
        by_id: {
          10: shipping_addresses[0],
          20: shipping_addresses[1],
          30: current_address,
          40: other_shipping_addresses[0],
          50: other_shipping_addresses[1]
        },
        current_delivery_address_id: 30
      },
      email_capture: {
        should_show_modal: false
      },
      payment_profile: {
        by_id: {100: payment_profiles[0], 200: payment_profiles[1]},
        user_payment_profile_ids: [100, 200]
      },
      user: {
        by_id: {1: {
          ...(_.omit(user, 'payment_profiles')),
          shipping_addresses: [10, 20]
        }},
        current_user_id: 1
      },
      cart_item: {
        cart_id: 1
      }
    });
  });

  describe('redux store compatibility', () => {
    // In order to see if we're hitting redux's "unexpected key" warning, we mock console.error for this test set
    // This is fragile and relies on an implementation detail of redux, we should look into better ways to accomplish it.
    const original_console_error = console.error;
    beforeEach(() => {
      // reset the mock for each test
      global.console.error = jest.fn(original_console_error);
    });
    afterAll(() => {
      // cleanup console.error mock
      global.console.error = original_console_error;
    });

    it('returns data that is consumable by redux', () => {
      global.Data = { user: user };
      mb_cookie.get.mockReturnValueOnce(current_address);

      createStore(baseReducer, getBootstrappedState());
      expect(console.error).not.toHaveBeenCalled();
    });
  });
});
