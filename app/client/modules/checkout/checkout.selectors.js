// @flow
import { isEmpty, map, get, uniq, compact, filter, includes, memoize } from 'lodash';
import { createSelector } from 'reselect';
import { cart_item_selectors } from 'store/business/cart_item';
import { selectCurrentPaymentProfileId } from 'client/modules/paymentProfile/paymentProfile.dux';
import { selectOrderItemsFromCart, selectOrderItemsFromCartComplete } from '../cartItem/cartItem.dux';
import { selectCurrentDeliveryAddress } from '../address/address.dux';

const localState = state => state.checkout;
export const selectPaymentInfoForm = state => localState(state).paymentInfoForm;
export const selectCheckoutOrder = state => localState(state).order;
export const selectCheckoutAddress = state => localState(state).address || selectCurrentDeliveryAddress(state);
export const selectPickupDetails = state => localState(state).pickup;
export const selectCheckoutAddressFormEditing = state => localState(state).addressEditing;
export const selectCheckoutAddressEditing = state => {
  const address = selectCheckoutAddress(state);
  const pickup = selectPickupDetails(state);
  const hasAddress = get(address, 'id') && get(address, 'phone');
  const hasPickup = get(pickup, 'id') && get(pickup, 'phone');
  return !(hasAddress || hasPickup) || selectCheckoutAddressFormEditing(state);
};
export const selectPaymentInformationEditing = state => localState(state).paymentInfoForm.paymentInfoFormEditing;
export const selectOrderFetching = state => localState(state).orderLoading;
export const selectOrderFinalizing = state => localState(state).orderFinalizing;
export const selectReplenishment = state => localState(state).replenishment;
export const selectCheckoutSchedulingByDeliveryMethodId = state => localState(state).scheduling;
export const selectIsUserGuest = state => localState(state).isGuest;
export const selectGuestPassword = state => localState(state).guestPassword;
export const selectShouldChangeTip = state => localState(state).changeTip;
export const selectGuestPasswordCreated = state => localState(state).guestCreated;
export const selectOrderReady = state => {
  const { id: shipping_address_id } = selectCheckoutAddress(state) || {};
  const checkoutAddressEditing = selectCheckoutAddressEditing(state);
  const pickupDetails = selectPickupDetails(state);
  const { paymentProfileId, paymentInfoFormEditing: isEditingPaymentInfo } = selectPaymentInfoForm(state);
  return (shipping_address_id || (get(pickupDetails, 'id'))) && paymentProfileId && !checkoutAddressEditing && !isEditingPaymentInfo;
};
export const selectIsModalOpen = state => !isEmpty(localState(state).modal);
export const selectModal = state => localState(state).modal || {};

const selectPaymentFetching = () => false;
const selectDeliveryFetching = () => false;
const selectPickupFetching = () => false;

export const selectShippingOptions = createSelector(
  selectOrderItemsFromCartComplete,
  cartItems => {
    const types = uniq(compact(map(cartItems, item => get(item, 'deliveryMethod.type', ''))));
    const hasShipping = !!filter(types, t => t !== 'pickup').length;
    const hasPickup = includes(types, 'pickup');
    return {
      hasShipping,
      hasPickup
    };
  }
);

const getGiftOptions = memoize((message, recipient_phone, recipient_name) => {
  return ({ message, recipient_phone, recipient_name });
});
const getData = (number, order_items, payment_profile_id, gift_options, shippingOptions,
  shipping_address_id, delivery_notes, pickup_detail_id, replenishment, is_gift) => {
  const data = {
    number,
    order_items,
    payment_profile_id,
    pickup_detail_id: null,
    shipping_address_id: null,
    delivery_notes: null,
    gift_options: undefined,
    replenishment,
    is_gift
  };
  if (is_gift){
    data.gift_options = gift_options;
  }
  if (shipping_address_id && shippingOptions.hasShipping){ // TODO: if it's delivery
    data.shipping_address_id = shipping_address_id;
    data.delivery_notes = delivery_notes;
  }
  if (pickup_detail_id && shippingOptions.hasPickup){
    data.pickup_detail_id = pickup_detail_id; // TODO: if it's pickup
  }
  return data;
};

const setScheduleFor = schedule => ({
  scheduled_for: get(schedule, 'hour.start_time')
});

type OrderDataType = {
  number: ?Number,
  order_items: Array<Object>,
  payment_profile_id: ?Number,
  gift_options: ?Object,
  shipping_options: ?Object,
  shipping_address_id: ?Number,
  delivery_notes: ?String,
  pickup_detail_id: ?Number,
  replenishment: ?Object,
  is_gift: ?Boolean,
};
export const selectOrderData: OrderDataType = createSelector(
  selectCheckoutOrder,
  selectPaymentInfoForm,
  selectShippingOptions,
  selectCheckoutAddress,
  selectPickupDetails,
  selectOrderItemsFromCart,
  selectCheckoutSchedulingByDeliveryMethodId,

  selectReplenishment,
  selectCurrentPaymentProfileId,
  cart_item_selectors.cartFetchStatus,
  selectPaymentFetching, // TODO: fetching payment
  selectDeliveryFetching, // TODO: delivery/pickup details fetching
  selectPickupFetching, // TODO: pickupFetching
  selectOrderFetching,
  (order, paymentInfo, shippingOptions, checkoutAddress, pickupDetails, orderItemsFromCart, schedulingByDeliveryMethodId, replenishment, currentPaymentProfileId) => {
    /*, cartFetchStatus, paymentFetching, deliveryFetching, pickupFetching, orderFetching */
    const { isGift, message, recipient_phone, recipient_name } = checkoutAddress || {};
    const giftOptions = getGiftOptions(message, recipient_phone, recipient_name);
    const orderItems = map(orderItemsFromCart, item => Object.assign(item, setScheduleFor(schedulingByDeliveryMethodId[item.delivery_method_id])));
    return getData(
      order.number,
      orderItems,
      paymentInfo.paymentProfileId || currentPaymentProfileId,
      giftOptions,
      shippingOptions,
      checkoutAddress && checkoutAddress.id,
      checkoutAddress && checkoutAddress.delivery_notes,
      pickupDetails && pickupDetails.id,
      replenishment,
      isGift
    );
  }
);
