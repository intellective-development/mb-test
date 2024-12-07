// @flow

import * as React from 'react';
import I18n from 'store/localization';
import DeliveryMethodIcon from 'store/views/compounds/DeliveryMethodIcon';

import { MBModal, MBText, MBLayout, MBButton } from '../../../elements';

type SupplierChangeConfirmModalProps = {
  show: boolean,
  header: string,
  is_shipping: boolean,
  message: string,
  confirm(): void,
  deny(): void,
}
const SupplierChangeConfirmModal = ({ header, message, is_shipping, confirm, deny, show }: SupplierChangeConfirmModalProps) => (
  <MBModal.Modal
    show={show}
    onHide={deny}
    size="small">
    <MBModal.SectionHeader renderRight={() => <MBModal.Close onClick={deny} />} />
    <div className="modal-container bottom-border">
      <MBText.H3 className="search-switch-confirm__header">{header}</MBText.H3>
      <MBText.P className="search-switch-confirm__body">{message}</MBText.P>
      {is_shipping && (
        <div className="search-switch-confirm__shipping-info">
          <DeliveryMethodIcon className="search-switch-confirm__shipping-icon" delivery_method_type="shipped" active />
          <MBText.P className="search-switch-confirm__shipping-text">
            {I18n.t('ui.supplier_change_modal.shipping_time_estimate')}
          </MBText.P>
        </div>
      )}
      <MBLayout.ButtonGroup>
        <MBButton className="search-switch-confirm__button" expand type="hollow" onClick={deny}>
          {I18n.t('ui.supplier_change_modal.cancel')}
        </MBButton>
        <MBButton className="search-switch-confirm__button" expand onClick={confirm}>
          {I18n.t('ui.supplier_change_modal.confirm')}
        </MBButton>
      </MBLayout.ButtonGroup>
    </div>
  </MBModal.Modal>
);

export default SupplierChangeConfirmModal;
