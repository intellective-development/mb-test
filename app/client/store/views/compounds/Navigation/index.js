// @flow

import * as React from 'react';

import AddToCartModal from 'product_browse/AddToCartModal';

import DesktopNavigation from './DesktopNavigation';
import MobileNavigation from './MobileNavigation';
import ContactUs from './shared/ContactUs';
import DeliveryInfoModal from '../../scenes/DeliveryInfoModal';
import SupplierMap from '../../scenes/SupplierMap';

type NavigationProps = {|
  is_checking_out: boolean
|};
const Navigation = ({ is_checking_out }: NavigationProps) => {
  return (
    <div>
      <DesktopNavigation is_checking_out={is_checking_out} />
      <MobileNavigation is_checking_out={is_checking_out} />
      <DeliveryInfoModal />
      {!is_checking_out && <AddToCartModal />}
      <SupplierMap />
      <ContactUs />
    </div>
  );
};

export default Navigation;
