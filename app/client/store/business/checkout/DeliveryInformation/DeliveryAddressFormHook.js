// @flow
import { join, compact } from 'lodash';
import { useSelector, useDispatch } from 'react-redux';
import { selectCurrentUser } from 'modules/user/user.dux';
import { selectCurrentDeliveryAddress, selectLastSavedAddressLikeCurrent } from 'modules/address/address.dux';
import { selectCheckoutAddress } from 'modules/checkout/checkout.dux';
import { ui_actions } from 'store/business/ui';


// TODO: this can be shared
const useDeliveryAddressForm = (): {
  user: Object,
  openChangeAddressModal: () => void,
  address: Object,
  phone: String,
  checkoutAddress: Object,
  formattedAddress: String,
  fullName: String
} => {
  const dispatch = useDispatch();
  const user = useSelector(selectCurrentUser) || {};
  const address = useSelector(selectCurrentDeliveryAddress) || {};
  const addressLine = join(compact([address.address1, address.address2]), ', ');
  const formattedAddress = join(compact([addressLine, address.city, address.state, address.zip_code]), ', ');
  const checkoutAddress = useSelector(selectCheckoutAddress) || {};

  const phone = (useSelector(selectLastSavedAddressLikeCurrent) || {}).phone || '';
  return {
    user,
    fullName: join(compact([user.first_name, user.last_name]), ' '),
    openChangeAddressModal: dispatch.bind(this, ui_actions.showDeliveryInfoModal()),
    address,
    phone,
    checkoutAddress,
    formattedAddress,
    last_name: user.last_name,
    first_name: user.first_name
  };
};

export default useDeliveryAddressForm;
