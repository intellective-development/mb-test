// @flow
import { createAction } from 'redux-procedures';

/* actions */
export const ResetCheckoutAddress = createAction('RESET_ADDRESS');
export const SetCheckoutAddressEditing = createAction('SET_ADDRESS_EDITING');
export const SetCheckoutScheduleEditing = createAction('SET_SCHEDULE_EDITING');
export const SetPaymentInfo = createAction('SET_PAYMENT_INFO');
export const SetPaymentInfoEditing = createAction('SET_PAYMENT_INFO_EDITING');
export const SetPromoCodeError = createAction('SET_PROMO_CODE_ERROR');
export const SetDeliveryMethodSchedule = createAction('SET_DELIVERY_METHOD_SCHEDULE');
export const ShowPaymentProfilesListModal = createAction('SHOW_PROFILES_LIST_MODAL');
export const SetModalOpen = createAction('SHOW_CHECKOUT_MODAL');
export const SetReplenishment = createAction('SET_REPLENISHMENT');
export const SetUserAsGuest = createAction('SET_GUEST');
export const ResetGuestUser = createAction('RESET_GUEST');
export const ResetOrderData = createAction('RESET_ORDER_DATA');
export const ResetOrderNumber = createAction('RESET_ORDER_NUMBER');
export const SetGuestPassword = createAction('SET_GUEST_PASSWORD');
