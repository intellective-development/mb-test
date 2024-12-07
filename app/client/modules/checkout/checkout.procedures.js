import React from 'react';
import createProcedure, { ActionPromise } from 'redux-procedures';
import { map, get, compact, head, isEmpty, last, pick } from 'lodash';
import uuid from 'uuid/v4';
import { push } from 'connected-react-router';
import { cart_item_actions, cart_item_selectors } from 'store/business/cart_item';
import { createOrder, finalizeOrder, setGuestPassword, updateUser, updateOrder } from '@minibar/store-business/src/networking/api';

import { READY_STATUS } from '@minibar/store-business/src/utils/fetch_status';
import { selectDeliveryMethodById } from 'client/modules/deliveryMethod/deliveryMethod.dux';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { CreateAddressProcedure, CreatePickupProcedure } from 'client/modules/address/address.dux';
import { CreateProfileProcedure } from 'client/modules/paymentProfile/paymentProfile.dux';

import { ResetCheckoutAddress, SetPaymentInfo, SetGuestPassword, SetModalOpen, SetPromoCodeError, SetCheckoutAddressEditing, ResetGuestUser, ResetOrderData, ResetOrderNumber } from './checkout.actions';
import { selectCurrentUser, guestSignUp, loginWithCookies } from '../user/user.dux';
import { selectIsUserGuest, selectGuestPassword, selectOrderData } from './checkout.selectors';
import { guestCallWrapper } from '../user/guestAxios';
import { addModal } from '../../ModalQueue';
import PopupForm from '../../store/business/checkout/CheckoutLogin/PopupForm';

import { trackPurchase } from '../../../client/store/business/analytics/actions';

export const validateShipment = (shipment) => {
  if (shipment.scheduled && !shipment.scheduled_for){
    return {
      name: 'SchedulingIncomplete',
      message: 'Please, schedule your shipments!'
    };
  } else if (delivery_method_helpers.mustBeScheduled(shipment.delivery_method) && !shipment.scheduled_for){
    return {
      name: 'SchedulingMissing',
      message: 'Please, schedule your shipments!'
    };
  } else {
    return null;
  }
};

const createOrderWithError = async(payload, meta, store) => {
  if (READY_STATUS !== cart_item_selectors.cartFetchStatus(store.getState())){
    await ActionPromise('CART_ITEM:FETCH_CART__DONE');
    // TODO: show error if empty or errored
  }
  const callFn = payload.number ? updateOrder : createOrder;
  const params = payload.number ? [{ number: payload.number }, payload] : [payload];
  return (selectIsUserGuest(store.getState()) ? guestCallWrapper(callFn)(...params) : callFn(...params))
    .catch(e => {
      const { message, name } = e.error || {};
      if (name === 'DeliveryUnavailable'){
        return store.dispatch(ResetCheckoutAddress());
      }
      switch (message){
        // A list of exceptions to be treated
        case 'Invalid Order Number':
          store.dispatch(ResetOrderData());
          break;
        case 'Order is not in a state to be edited':
          store.dispatch(ResetOrderNumber());
          break;
        case 'Invalid Shipping Address ID':
          store.dispatch(ResetCheckoutAddress());
          break;
        case 'Invalid Payment Profile ID':
          store.dispatch(SetPaymentInfo(null));
          break;
        case 'Unable to parse response':
          if (meta && meta.finalize){
            store.dispatch(SetModalOpen({ title: 'Oh no!', message: <span>Something wrong happened while placing your order, please try again. If the problem persists, call us: <a className="text-link" href="tel:+18554870740">(855) 487-0740</a>. We’re sorry for any inconvenience.</span> }));
          }
          throw e;
        default:
          if (name === 'InvalidPromoCode'){
            store.dispatch(SetPromoCodeError(e.error));
          } else if (!isEmpty(message)){
            store.dispatch(SetModalOpen({ title: 'Oh no!', message }));
          }
          throw e;
      }
    });
};

// TODO: move it to utils
const removeEmpty = obj => {
  return Object.keys(obj).reduce((acc, key) => {
    if (obj[key] !== null){
      acc[key] = obj[key];
    }
    return acc;
  }, {});
};

const finalizeOrderWithError = (payload, store) => {
  return Promise.resolve()
    .then(() => {
      if (selectIsUserGuest(store.getState())){
        return SetGuestPassword(selectGuestPassword(store.getState()));
      }
    })
    .then(() => {
      const deliveryMethodById = selectDeliveryMethodById(store.getState());
      const validations = compact(map(compact(payload.order_items), item => {
        return validateShipment(({ ...item, delivery_method: deliveryMethodById[item.delivery_method_id] }));
      }));
      if (validations.length){
        const error = { error: head(validations) };
        if (get(error, 'error.message') === 'Please, schedule your shipments!'){
          store.dispatch(SetCheckoutAddressEditing(true));
        }
        throw error;
      }
      return finalizeOrder({ number: payload.number }, removeEmpty({...payload}), store);
    })
    .then(order => {
      if (selectIsUserGuest(store.getState())){
        store.dispatch(ResetGuestUser());
      }
      return order;
    })
    .catch(e => {
      const { message } = e.error || {};
      if (!isEmpty(message)){
        store.dispatch(SetModalOpen({
          title: 'Oh no!',
          message: !isEmpty(message) ? message : (<span>Something wrong happened while finalizing your order, please try again. If the problem persists, call us: <a className="text-link" href="tel:+18554870740">(855) 487-0740</a>. We’re sorry for any inconvenience.</span>)
        }));
      }
      throw e;
    });
};

const CreateOrderApi = async(payload, meta, store) => createOrderWithError(payload, meta, store);
const FinalizeOrderApi = async(payload, meta, store) => {
  return finalizeOrderWithError(payload, store)
    .then(order_entities => {
      const order = order_entities.entities.order[order_entities.result];

      store.dispatch(push(`/store/checkout/${payload.number}/success`));
      store.dispatch(cart_item_actions.deleteCart());
      store.dispatch(trackPurchase(order));
    });
};

/**
 * Creates or fetches a pending order from server or redux-store if already created and persisted
 */
export const CreateOrderProcedure = createProcedure('CREATE_ORDER_PROCEDURE', async(payload, meta, store) => {
  const user = selectCurrentUser(store.getState());
  // We may not clean up the credentials, then we'll have to update the account when the info provided/updated
  if (!user && !window.User.get('new_user')){
    await CreateDummyGuest();
  }
  const result = await CreateOrderApi(payload, meta, store);
  return result;
});
const finalizeApi = (payload, meta, store) => Promise.resolve()
  .then(() => {
    const password = selectGuestPassword(store.getState());
    if (selectIsUserGuest(store.getState()) && !isEmpty(password)){
      return SaveGuestPasswordProcedure(password)
        .catch(e => {
          const { message } = e.error || {};
          if (!isEmpty(message)){
            store.dispatch(SetModalOpen({ title: 'Oh no!', message }));
          }
          throw e;
        });
    }
  })
  .then(async() => {
    await CreateOrderApi(payload, { ...meta, finalize: true }, store);
    const number = get(selectOrderData(store.getState()), 'number');
    if (!isEmpty(number)){
      return payload;
    }
    const newOrder = await CreateOrderProcedure({...payload, number: null});
    return {...payload, number: get(newOrder, 'result')};
  })
  .then(p => FinalizeOrderApi(p, meta, store));

export const FinalizeOrderProcedure = createProcedure('FINALIZE_ORDER', (payload, meta, store) => {
  const wrapper = selectIsUserGuest(store.getState()) ? guestCallWrapper : fn => fn;
  return wrapper(finalizeApi)(payload, meta, store);
});

export const CreateDummyGuest = createProcedure('CREATE_DUMMY_GUEST', (form = {}, meta, store) => {
  return Promise.resolve()
    .then(() => {
      const user = selectCurrentUser(store.getState());
      if (!user && !window.User.get('new_user_token')){
        const password = uuid();
        const account_info = {
          isAnonymous: true,
          email: `${password}@minibardelivery.com`,
          contact_email: form.email,
          first_name: form.first_name || 'Guest',
          last_name: form.last_name || 'Account',
          password,
          password_confirmation: password,
          client_id: global.ClientId,
          client_secret: global.ClientSecret
        };
        return guestSignUp(account_info);
      }
    });
});

const updateGuestUserName = async(store, form) => {
  if (selectCurrentUser(store.getState())) return; // won't update registered user
  if (!window.User.get('new_user_token')) return; // can't update without a guest user
  const user = window.User.get('new_user');
  if (user && (user.first_name !== 'Guest' || user.last_name !== 'Account')) return; // won't update user-provided name

  const account_info = {
    first_name: head(form.name.split(' ')),
    last_name: last(form.name.split(' '))
  };
  const { entities, result } = await guestCallWrapper(updateUser)(pick(account_info, ['first_name', 'last_name', 'contact_email']));
  const newUser = get(entities, 'user', {})[get(result, 'user')];
  window.User.set('new_user', newUser);
};

const updateGuestUser = async(store, form) => {
  const user = selectCurrentUser(store.getState());
  if (!user){
    const password = uuid();
    const account_info = {
      email: `${password}@minibardelivery.com`,
      contact_email: form.email,
      first_name: form.first_name || 'Guest',
      last_name: form.last_name || 'Account',
      password,
      password_confirmation: password,
      client_id: global.ClientId,
      client_secret: global.ClientSecret
    };
    if (!window.User.get('new_user_token')){ // highly unlikely
      return guestSignUp(account_info);
    } else {
      try {
        const { entities, result } = await guestCallWrapper(updateUser)(pick(account_info, ['first_name', 'last_name', 'contact_email']));
        const newUser = get(entities, 'user', {})[get(result, 'user')];
        window.User.set('new_user', newUser);
      } catch (e){
        const errorMessage = get(e, 'error.message', {});
        if (errorMessage === 'Email address belongs to an existing user.'){
          addModal({
            title: 'Login',
            id: 'email-already-exists',
            contents: <PopupForm email={account_info.contact_email} />
          });
          const errorObject = { error: { message: undefined }};
          throw errorObject;
        }
        const errorObject = { error: { message: errorMessage } };
        throw errorObject;
      }
    }
  }
};

export const SaveCheckoutAddressProcedure = createProcedure('SAVE_CHECKOUT_ADDRESS_PROCEDURE', (form, meta, store) => {
  return Promise.resolve()
    .then(() => updateGuestUser(store, form))
    .then(() => {
      return CreateAddressProcedure({
        ...form.address,
        name: form.isGift ? form.recipient_name : `${form.first_name} ${form.last_name}`,
        phone: form.phone,
        address2: form.address2 || '',
        company: form.isBusiness === 'true' ? form.company : undefined
      }, meta, store);
    })
    .then(payload => {
      store.dispatch({ type: 'ADDRESS:SET_DELIVERY_ADDRESS__SUCCESS', payload });
      return payload;
    })
    .catch(e => {
      const { message } = e.error || {};
      if (message === 'Unable to parse response'){
        store.dispatch(SetModalOpen({ title: 'Oh no!', message: <span>Something wrong happened while saving your delivery address, please try again. If the problem persists, call us: <a className="text-link" href="tel:+18554870740">(855) 487-0740</a>. We’re sorry for any inconvenience.</span> }));
      } else if (!isEmpty(message)){
        store.dispatch(SetModalOpen({ title: 'Oh no!', message }));
      }
      throw e;
    });
});

export const SavePaymentInfoProcedure = createProcedure('SAVE_CHECKOUT_PAYMENT_INFO_PROCEDURE', (form, meta, store) => {
  return CreateProfileProcedure(form, meta, store)
    .then(() => updateGuestUserName(store, form))
    .catch(e => {
      const { message } = e.error || {};
      if (message === 'Unable to parse response'){
        store.dispatch(SetModalOpen({ title: 'Oh no!', message: <span>Something wrong happened while saving your payment information, please try again. If the problem persists, call us: <a className="text-link" href="tel:+18554870740">(855) 487-0740</a>. We’re sorry for any inconvenience.</span> }));
      } else if (!isEmpty(message)){
        store.dispatch(SetModalOpen({ title: 'Oh no!', message }));
      }
      throw e;
    });
});

export const SavePickupDetailsProcedure = createProcedure('SAVE_PICKUP_DETAILS_PROCEDURE', (form, meta, store) => {
  return Promise.resolve()
    .then(() => updateGuestUser(store, form))
    .then(() => {
      return CreatePickupProcedure({ ...form, name: `${form.first_name} ${form.last_name}` }, meta, store);
    })
    .catch(e => {
      const { message } = e.error || {};
      if (message === 'Unable to parse response'){
        store.dispatch(SetModalOpen({ title: 'Oh no!', message: <span>Something wrong happened while saving your pickup details, please try again. If the problem persists, call us: <a className="text-link" href="tel:+18554870740">(855) 487-0740</a>. We’re sorry for any inconvenience.</span> }));
      } else if (!isEmpty(message)){
        store.dispatch(SetModalOpen({ title: 'Oh no!', message }));
      }
      throw e;
    });
});

export const SaveGuestPasswordProcedure = createProcedure('SAVE_GUEST_PASSWORD_PROCEDURE', (password) => {
  const wrapper = guestCallWrapper;
  return wrapper(setGuestPassword)({
    password,
    password_confirmation: password
  })
    .then(({ result }) => {
      return loginWithCookies({
        email: result.email,
        password
      });
    });
});
