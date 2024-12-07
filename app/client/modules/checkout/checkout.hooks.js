// @flow
import { useEffect, useRef, useCallback } from 'react';
import { isEqual, isEmpty, get, map, keys, omit } from 'lodash';
import { useDispatch, useSelector } from 'react-redux';
import { cart_item_selectors } from 'store/business/cart_item';
import { selectCurrentUser } from 'modules/user/user.dux';
import { READY_STATUS } from '@minibar/store-business/src/utils/fetch_status';
import { selectCurrentPaymentProfileId } from 'modules/paymentProfile/paymentProfile.dux';
import { delivery_method_helpers } from 'store/business/delivery_method';
import { selectPaymentInfoForm, selectCheckoutOrder, selectOrderFetching, selectOrderData, selectPaymentInformationEditing, selectShouldChangeTip, selectIsUserGuest, selectCheckoutSchedulingByDeliveryMethodId } from './checkout.selectors';
import { ShowPaymentProfilesListModal, SetPaymentInfo, ResetOrderData } from './checkout.actions';
import { CreateOrderProcedure } from './checkout.procedures';
import { selectOrderItemsFromCart, selectShipmentsGrouped } from '../cartItem/cartItem.dux';
import { selectDeliveryMethodById } from '../deliveryMethod/deliveryMethod.dux';
import { selectSelectedDeliveryMethodBySupplierId } from '../supplier/supplier.dux';
import { selectAddresses, selectCurrentDeliveryAddress } from '../address/address.dux';
import { findStoreableAddress } from '../../store/views/compounds/AddressEntry/utils';

export const usePaymentInformation = (): {
  paymentProfileId: Number,
  isEditing: Boolean,
  openPaymentProfilesList: () => {}
} => {
  const dispatch = useDispatch();
  const { paymentProfileId } = useSelector(selectPaymentInfoForm);
  const currentPaymentProfileId = useSelector(selectCurrentPaymentProfileId);
  const isEditing = useSelector(selectPaymentInformationEditing);
  const isGuest = useSelector(selectIsUserGuest);
  const openPaymentProfilesList = () => dispatch(ShowPaymentProfilesListModal(true));

  useEffect(() => {
    if (currentPaymentProfileId && !paymentProfileId && !isGuest){
      dispatch(SetPaymentInfo(currentPaymentProfileId));
    }
  }, []);

  return {
    isEditing,
    paymentProfileId,
    openPaymentProfilesList
  };
};

type UseCheckoutOrderType = {
  order: Object,
  cartReady: boolean,
  orderItems: Array<>,
  orderFetching: boolean,
  finalizeCheckoutOrder: () => void
}

export const useCheckoutOrder = (): UseCheckoutOrderType => {
  const order = useSelector(selectCheckoutOrder);
  const orderFetching = useSelector(selectOrderFetching);
  const cartStatus = useSelector(cart_item_selectors.cartFetchStatus);
  const cartReady = cartStatus === READY_STATUS;
  const orderItems = useSelector(selectOrderItemsFromCart);
  // TODO refactor this chunk?
  return ({
    order,
    orderFetching,
    orderItems,
    cartReady,
    finalizeCheckoutOrder: () => {}
  });
};

export const useAllShipmentsReady = () => {
  const shipments = useSelector(selectShipmentsGrouped);
  const deliveryMethodById = useSelector(selectDeliveryMethodById);
  const selectedBySupplierId = useSelector(selectSelectedDeliveryMethodBySupplierId);
  const checkoutSchedulesById = useSelector(selectCheckoutSchedulingByDeliveryMethodId) || {};
  const allShipmentsReady = () => map(keys(shipments), (supplierId) => {
    const selected = selectedBySupplierId[supplierId];
    const selectedDeliveryMethod = deliveryMethodById[selected];

    if (!delivery_method_helpers.mustBeScheduled(selectedDeliveryMethod)) return true;

    // Otherwise, let's check if schedule has been fully selected.
    const schedule = checkoutSchedulesById[selected] || {};
    return !!schedule.day && !!schedule.hour;
  }).every(valid => valid); // All shipments must be valid
  const areAllShipmentsReady = useCallback(allShipmentsReady());
  return areAllShipmentsReady;
};

function useWhyDidYouUpdate(name, props){
  // Get a mutable ref object where we can store props ...
  // ... for comparison next time this hook runs.
  const previousProps = useRef();
  useEffect(() => {
    if (previousProps.current){
      // Get all keys from previous and current props
      const allKeys = Object.keys({ ...previousProps.current, ...props });
      // Use this object to keep track of changed props
      const changesObj = {};
      // Iterate through keys
      allKeys.forEach(key => {
        // If previous is different from current
        if (previousProps.current[key] !== props[key]){
          // Add to changesObj
          changesObj[key] = {
            from: previousProps.current[key],
            to: props[key]
          };
        }
      });

      // If changesObj not empty then output to console
      if (Object.keys(changesObj).length){
        console.warn('[why-did-you-update]', name, changesObj);
      }
    }

    // Finally update previousProps with current props for next hook call
    previousProps.current = props;
  });
}

function deepCompareEquals(a, b){
  // TODO: implement deep comparison here
  // something like lodash
  return isEqual(a, b);
}

function useDeepCompareMemoize(value){
  const ref = useRef();
  // it can be done by using useMemo as well
  // but useRef is rather cleaner and easier

  if (!deepCompareEquals(value, ref.current)){
    ref.current = value;
  }

  return ref.current;
}

function useDeepCompareEffect(callback, dependencies){
  useEffect(callback, useDeepCompareMemoize(dependencies));
}

/**
 * When mounted creates/updates the order with data from checkout information: delivery/payment/refill options and cart contents.
 * Returns same data as useCheckoutOrder
 */
export const useCheckoutOrderEffect = (): UseCheckoutOrderType => {
  const dispatch = useDispatch();

  // const order_items = useSelector(selectOrderItemsFromCart);
  const orderData = useSelector(selectOrderData);
  const user = useSelector(selectCurrentUser);
  const order = useSelector(selectCheckoutOrder);
  const shouldChangeTip = useSelector(selectShouldChangeTip);

  // const cartFetchStatus = useSelector(cart_item_selectors.cartFetchStatus);
  // const paymentFetching = false; // TODO: fetching payment
  // const deliveryFetching = false; // TODO: delivery/pickup details fetching
  // const cartReady = READY_STATUS === cartFetchStatus && order_items.length > 0;
  // const paymentReady = !!orderData.payment_profile_id;
  // const deliveryReady = !!(orderData.shipping_address_id || orderData.pickup_detail_id);

  // const orderFetching = useSelector(selectOrderFetching);
  // const fetching = paymentFetching || deliveryFetching; // If anything except the order is being applier on the server
  // const checkoutReady = cartReady && paymentReady && deliveryReady; // If anything is not yet prepared

  useWhyDidYouUpdate('orderData', orderData);
  // Try to create an order when it's mounted
  //console.log('hook', orderData);
  const abstractOrderData = omit(orderData, 'number');
  useDeepCompareEffect(() => {
    const isUserOrGuest = (!!user || !isEmpty(window.User.get('new_user')));
    const hasItems = get(orderData, 'order_items.length');
    const hasSavedOrder = get(order, 'number');
    if (hasItems && (isUserOrGuest || !hasSavedOrder)){
      const orderDataSent = { ...orderData };
      if (shouldChangeTip && orderDataSent.tip === undefined){
        orderDataSent.tip = null;
      }
      CreateOrderProcedure(orderDataSent);
    }
  }, [abstractOrderData, user]);

  const isGuest = useSelector(selectIsUserGuest);
  const addresses = useSelector(selectAddresses);
  const currentAddress = useSelector(selectCurrentDeliveryAddress);
  useEffect(() => {
    // THIS SHOULD CLEAR EVERYTHING AS IF THE ORDER HAS JUST BEEN PLACED.
    // It might help to prevent leftovers when swithching between accounts and other things like that
    dispatch(ResetOrderData());
    const storeableAddress = findStoreableAddress(currentAddress, addresses);
    if (!isGuest && !get(currentAddress, 'id') && get(storeableAddress, 'id')){
      dispatch({
        type: 'ADDRESS:SAVE_DELIVERY_ADDRESS__SUCCESS',
        payload: { entities: { address: {} } },
        meta: { address_id: storeableAddress.local_id }
      });
    }
    if (isGuest && get(currentAddress, 'id')){
      const local_id = get(currentAddress, 'local_id');
      const localAddress = omit(currentAddress, 'id');
      dispatch({
        type: 'ADDRESS:SAVE_DELIVERY_ADDRESS__SUCCESS',
        payload: { entities: { address: { [local_id]: localAddress } } },
        meta: { address_id: local_id }
      });
    }
  }, []);

  // create/update order
  // select scheduling options

  return useCheckoutOrder();
};
