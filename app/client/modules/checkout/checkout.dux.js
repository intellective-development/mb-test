import { combineReducers } from 'redux';
import { get, includes } from 'lodash';
import { persistReducer } from 'redux-persist';
import storage from 'redux-persist/lib/storage';
import {
  SetModalOpen,
  SetPaymentInfoEditing,
  SetCheckoutAddressEditing,
  SetReplenishment,
  ResetCheckoutAddress,
  SetPaymentInfo,
  ShowPaymentProfilesListModal,
  SetPromoCodeError,
  SetDeliveryMethodSchedule,
  SetCheckoutScheduleEditing,
  SetUserAsGuest,
  ResetGuestUser,
  SetGuestPassword,
  ResetOrderData,
  ResetOrderNumber
} from './checkout.actions';
import {
  CreateOrderProcedure,
  SaveCheckoutAddressProcedure,
  FinalizeOrderProcedure,
  SavePickupDetailsProcedure,
  SaveGuestPasswordProcedure
} from './checkout.procedures';

const paymentInfoFormReducer = (state = {
  paymentProfileId: null,
  paymentInfoFormEditing: false,
  modalOpen: false
}, action) => {
  switch (action.type){
    case ShowPaymentProfilesListModal().type:
      return {
        ...state,
        modalOpen: !!action.payload
      };
    case SetPaymentInfoEditing().type:
      return {
        ...state,
        paymentInfoFormEditing: action.payload
      };
    case SetPaymentInfo().type:
      return {
        ...state,
        paymentProfileId: action.payload,
        paymentInfoFormEditing: false,
        modalOpen: false
      };
    case `${SetUserAsGuest}`:
    case `${ResetGuestUser}`:
      return {
        paymentInfoFormEditing: true,
        paymentProfileId: null,
        modalOpen: false
      };
    default:
      return state;
  }
};

const checkoutAddressReducer = (state = null, action) => {
  const { entities, result } = action.payload || {};
  switch (action.type){
    case SaveCheckoutAddressProcedure.TRIGGER:
      return {
        ...state,
        ...action.payload
      };
    case SavePickupDetailsProcedure.TRIGGER:
      return {
        ...state,
        isGift: action.payload.isGift,
        recipient_phone: '',
        recipient_name: '',
        message: ''
      };
    case ResetCheckoutAddress().type:
    case `${SetUserAsGuest}`:
      return null;
    case SaveCheckoutAddressProcedure.SUCCESS:
      return {
        ...state,
        ...entities.address[result]
      };
    case FinalizeOrderProcedure.SUCCESS:
      return {
        ...state,
        delivery_notes: '',
        message: '',
        isGift: false
      };
    default:
      return state;
  }
};

const pickupAddressReducer = (state = null, action) => {
  const { entities, result } = action.payload || {};
  switch (action.type){
    case SavePickupDetailsProcedure.TRIGGER:
      return {
        ...state,
        ...action.payload
      };
    case SavePickupDetailsProcedure.SUCCESS:
      return {
        ...state,
        ...entities.pickup_detail[result]
      };
    case `${SetUserAsGuest}`:
      return null;
    default:
      return state;
  }
};

const checkoutAddressEditingReducer = (state = false, action) => {
  switch (action.type){
    case ResetCheckoutAddress().type:
    case SaveCheckoutAddressProcedure.SUCCESS:
    case SavePickupDetailsProcedure.SUCCESS:
      return false;
    case SetCheckoutAddressEditing().type:
      return !!action.payload;
    default:
      return state;
  }
};

const checkoutScheduleEditingReducer = (state = true, action) => {
  switch (action.type){
    case SetCheckoutScheduleEditing().type:
      return !!action.payload;
    case `${SetUserAsGuest}`:
      return true;
    default:
      return state;
  }
};

const replenishmentReducerInitialState = {
  enabled: false,
  interval: 7
};
const replenishmentReducer = (state = replenishmentReducerInitialState, action) => {
  switch (action.type){
    case SetReplenishment().type:
      return {
        ...state,
        ...action.payload
      };
    case FinalizeOrderProcedure.SUCCESS:
      return replenishmentReducerInitialState;
    default:
      return state;
  }
};

const orderFetchingReducer = (state = false, action) => {
  switch (action.type){
    case CreateOrderProcedure.TRIGGER:
      return true;
    case CreateOrderProcedure.FULFILL:
      return false;
    default:
      return state;
  }
};

const orderFinalizingReducer = (state = false, action) => {
  switch (action.type){
    case FinalizeOrderProcedure.TRIGGER:
      return true;
    case FinalizeOrderProcedure.FULFILL:
      return false;
    default:
      return state;
  }
};


const orderReducer = (state = {}, action) => {
  const success_entities = get(action, 'payload.entities.order') || {};
  const success_result = get(action, 'payload.result') || {};
  const result_entity = success_entities[success_result] || {};
  const { message, amounts } = get(action, 'payload') || {};
  const promoCodeError = includes(message, 'REMOVE_PROMO_CODE') ? '' : message;

  switch (action.type){
    case CreateOrderProcedure.SUCCESS:
      return {
        ...state,
        ...result_entity,
        promoCodeError: '',
        tip: get(result_entity, 'amounts.tip', undefined),
        gift_options: get(result_entity, 'gift_options')
      };
    case FinalizeOrderProcedure.SUCCESS:
    case `${SetUserAsGuest}`:
    case `${ResetOrderData}`:
      return {};
    case `${ResetOrderNumber}`:
      return {
        ...state,
        number: null
      };
    case SetPromoCodeError().type:
      return {
        ...state,
        promo_code: '',
        promoCodeError,
        amounts
      };
    default:
      return state;
  }
};

const modalReducer = (state = {}, action) => {
  switch (action.type){
    case SetModalOpen().type:
      return action.payload;
    default:
      return state;
  }
};

const schedulingReducer = (state = {}, action) => {
  switch (action.type){
    case SetDeliveryMethodSchedule().type:
      return {
        ...state,
        [action.payload.id]: action.payload
      };
    case FinalizeOrderProcedure.SUCCESS:
      return {};
    default:
      return state;
  }
};

const guestReducer = (state = false, action) => {
  switch (action.type){
    case `${SetUserAsGuest}`:
      return !!action.payload;
    case SaveGuestPasswordProcedure.SUCCESS:
    case ResetGuestUser:
      return false;
    default:
      return state;
  }
};

const guestPasswordReducer = (state = '', action) => {
  switch (action.type){
    case `${SetGuestPassword}`:
      return action.payload;
    case SaveGuestPasswordProcedure.SUCCESS:
      return '';
    default:
      return state;
  }
};

const guestPasswordCreatedReducer = (state = false, action) => {
  switch (action.type){
    case SaveGuestPasswordProcedure.SUCCESS:
      return true;
    default:
      return state;
  }
};

const changeTipReducer = (state = true, action) => {
  switch (action.type){
    case 'CART_ITEM:UPDATE_QUANTITY':
      return true;
    case CreateOrderProcedure.TRIGGER:
      if (get(action, 'payload.tip', null) !== null){
        return false;
      } else {
        return state;
      }
    default:
      return state;
  }
};

const persistConfig = {
  key: 'checkout',
  storage,
  blacklist: [
    'modal',
    'isGuest',
    'guestPassword',
    'guestCreated',
    'orderLoading',
    'orderFinalizing',
    'scheduling'
  ]
};

export default persistReducer(persistConfig, (state = {}, action) => {
  if (state.isGuest && action.type === FinalizeOrderProcedure.SUCCESS){
    return combineReducers({
      paymentInfoForm: () => paymentInfoFormReducer(undefined, {}),
      order: () => orderReducer(undefined, {}),
      orderLoading: () => orderFetchingReducer(undefined, {}),
      orderFinalizing: () => orderFinalizingReducer(undefined, {}),
      modal: () => modalReducer(undefined, {}),
      address: () => checkoutAddressReducer(undefined, {}),
      pickup: () => pickupAddressReducer(undefined, {}),
      addressEditing: () => checkoutAddressEditingReducer(undefined, {}),
      scheduling: () => schedulingReducer(undefined, {}),
      schedulingEditing: () => checkoutScheduleEditingReducer(undefined, {}),
      replenishment: () => replenishmentReducer(undefined, {}),
      isGuest: guestReducer,
      guestPassword: guestPasswordReducer,
      guestCreated: guestPasswordCreatedReducer,
      changeTip: () => changeTipReducer(undefined, {})
    })(state, action);
  }
  return combineReducers({
    paymentInfoForm: paymentInfoFormReducer,
    order: orderReducer,
    orderLoading: orderFetchingReducer,
    orderFinalizing: orderFinalizingReducer,
    modal: modalReducer,
    address: checkoutAddressReducer,
    pickup: pickupAddressReducer,
    addressEditing: checkoutAddressEditingReducer,
    scheduling: schedulingReducer,
    schedulingEditing: checkoutScheduleEditingReducer,
    replenishment: replenishmentReducer,
    isGuest: guestReducer,
    guestPassword: guestPasswordReducer,
    guestCreated: guestPasswordCreatedReducer,
    changeTip: changeTipReducer
  })(state, action);
});

export * from './checkout.actions';
export * from './checkout.selectors';
export * from './checkout.procedures';
