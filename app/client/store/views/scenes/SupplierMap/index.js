// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { ui_actions, ui_selectors } from 'store/business/ui';

import { MBModal } from '../../elements';
import SupplierLocationMap from './SupplierLocationMap';

type SupplierMapModalProps = {show: number, supplier_id: number, dismiss: Function};
export const SupplierMapModal = ({show, supplier_id, dismiss}: SupplierMapModalProps) => {
  return (
    <MBModal.Modal size="large" show={show} onHide={dismiss} >
      <MBModal.SectionHeader
        renderRight={() => <MBModal.Close onClick={dismiss} />} />
      <SupplierLocationMap supplier_id={supplier_id} />
    </MBModal.Modal>
  );
};

const SupplierMapModalSTP = (state) => ({
  show: ui_selectors.showSupplierMap(state),
  supplier_id: ui_selectors.mapSupplierId(state)
});
const SupplierMapModalDTP = {dismiss: ui_actions.hideSupplierMapModal};
const SupplierMapModalContainer = connect(SupplierMapModalSTP, SupplierMapModalDTP)(SupplierMapModal);

export default SupplierMapModalContainer;
