import { delivery_method_helpers } from '../../store/business/delivery_method';

const localState = ({ delivery_method }) => delivery_method;

export const selectDeliveryMethodById = state => localState(state).by_id;


export const displayName = delivery_method_helpers.displayName;
