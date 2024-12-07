import * as React from 'react';
import { MBModal, MBText } from 'store/views/elements';

//standard alert modal
const AlertBox = ({show, onHide, message, title, error_cta = 'Got it!'}) => (
  <MBModal.Modal
    show={show}
    onHide={onHide}
    size="tiny" >
    <MBModal.SectionHeader
      renderRight={() => <MBModal.Close onClick={onHide} />}>
      {title}
    </MBModal.SectionHeader>
    <div className="modal-container">
      <MBText.P body_copy>{message}</MBText.P><br />
      <a className="button expand" onClick={onHide}>
        {error_cta}
      </a>
    </div>
  </MBModal.Modal>
);

export default AlertBox;
