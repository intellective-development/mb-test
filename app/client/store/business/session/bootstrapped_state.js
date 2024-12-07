// @flow

import _ from 'lodash';
import uuid from 'uuid';
import * as mb_cookie from 'store/business/utils/mb_cookie';
import { isMobile } from 'store/business/utils/is_mobile';
import { EMAIL_CAPTURE_COOKIE_NAME } from 'store/business/email_capture/constants';
import { formatUserResponse } from '@minibar/store-business/src/networking/api';

// Enables us to synchronously inject the data we're getting from the server into the redux state where necessary:
// 1. On App Init - the backbone app requires a synchronous address to be available, having it in the redux state from the start
// is an easy way to ensure the legacy Address model can grab it when it iniitializes.
// 2. On Rehydrate - Ensuress that the data from cookie/initial state doesn't get overwritten by null when there is no persisted data,
// or by a different address when there is data.
// 3. Ensures that places where our stored data overlaps (user past addresses, etc.) are handled in a predictable way

// TODO: cart items from local storage
const getBootstrappedState = (initial_state: GlobalState = {}) => {
  const cart_id = _.get(window, 'Data.cart_id');
  const raw_user_data = _.get(window, 'Data.user') || _.get(window, 'Entry.User'); // TODO: consolidate this
  const user_has_seen_modal = mb_cookie.get(EMAIL_CAPTURE_COOKIE_NAME);
  const user_is_on_mobile = isMobile();

  const cart_id_state = formatCartIdState(cart_id);
  const user_state = formatUserState(raw_user_data);
  const address_state = formatDeliveryAddressState(getAddressInCookie());
  const email_capture_modal_state = formatEmailCaptureModalState(raw_user_data, user_has_seen_modal, user_is_on_mobile);

  // perform a deep merge on each of the state sources
  // note that the ordering is significant - in the case of conflicts,
  // the arguments to the right overwrite those to the left.
  return _.merge(
    {},
    initial_state,
    cart_id_state,
    email_capture_modal_state,
    user_state,
    address_state
  );
};

const formatDeliveryAddressState = (bootstrapped_data) => {
  if (!bootstrapped_data) return {};

  return {
    address: {
      by_id: {
        [bootstrapped_data.local_id]: bootstrapped_data
      },
      current_delivery_address_id: bootstrapped_data.local_id
    }
  };
};

const formatEmailCaptureModalState = (bootstrapped_user_data: Object, user_has_seen_modal: boolean, user_is_on_mobile: boolean) => {
  const user_exists = !(_.isEmpty(bootstrapped_user_data));

  return {
    email_capture: {
      should_show_modal: !(user_exists || user_has_seen_modal || user_is_on_mobile)
    }
  };
};

const formatUserState = (bootstrapped_user_data: Object) => {
  if (_.isEmpty(bootstrapped_user_data)) return {};

  const formatted_data = formatUserResponse(bootstrapped_user_data);
  const normalized_user = formatted_data.entities.user;

  return {
    user: {
      by_id: normalized_user,
      current_user_id: formatted_data.result.user
    },
    payment_profile: {
      by_id: formatted_data.entities.payment_profile,
      user_payment_profile_ids: formatted_data.result.payment_profiles
    },
    address: {
      by_id: formatted_data.entities.address
    }
  };
};

const formatCartIdState = (cart_id: ?number) => ({
  cart_item: {
    cart_id
  }
});

export default getBootstrappedState;
export const __private__ = {
  formatDeliveryAddressState,
  formatUserState,
  formatEmailCaptureModalState,
  formatCartIdState
};


// grab the address from the cookie.
const getAddressInCookie = () => {
  const saved_addr = mb_cookie.get('address');

  if (saved_addr){
    // to support legacy cookies, we inject an local_id.
    // cookies that already have a local_id will overwrite the new one.
    return {
      local_id: uuid(),
      ...saved_addr
    };
  } else {
    return null;
  }
};
