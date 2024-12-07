// @flow

import * as React from 'react';

import { MBModal } from '../../../elements';
import SupplierLocationMap from '../../SupplierMap/SupplierLocationMap';

type SupplierMapProps = {supplier_id: number, routeBack: Function, hideModal: Function};
const SupplierMap = ({supplier_id, routeBack, hideModal}: SupplierMapProps) => {
  return (
    <div>
      <MBModal.SectionHeader
        renderLeft={() => <MBModal.Back onClick={routeBack} />}
        renderRight={() => <MBModal.Close onClick={hideModal} />} />
      <SupplierLocationMap supplier_id={supplier_id} />
    </div>
  );
};

export default SupplierMap;
