import React, { Fragment } from 'react';
import { getGlobal, setGlobal, useGlobal } from 'reactn';
import isEmpty from 'lodash/isEmpty';
import values from 'lodash/values';
import omit from 'lodash/omit';
import uuid from 'uuid/v4';
import { Portal } from 'react-portal';

import { Modal, SectionHeader, Close } from './store/views/elements/MBModal';

setGlobal({ modals: {} });

export const addModal = ({
  id = uuid(),
  ...props
}) => {
  const { modals, ...globals } = getGlobal();
  modals[id] = { id, ...props };
  setGlobal({ modals, ...globals });
};

export const removeModal = (id) => {
  const { modals, ...globals } = getGlobal();
  setGlobal({ modals: omit(modals, id), ...globals });
};

const ModalQueue = () => {
  const [modals] = useGlobal('modals');
  if (isEmpty(modals)){
    return null;
  }
  return (
    <Fragment>
      {values(modals).map(modal => {
        return (
          <Portal key={modal.id}>
            <Modal
              show
              size="small" >
              <SectionHeader
                renderRight={() => <Close onClick={() => removeModal(modal.id)} />}>
                {modal.title}
              </SectionHeader>
              <div className="modal-container">
                {modal.contents}
              </div>
            </Modal>
          </Portal>
        );
      })}
    </Fragment>
  );
};

export default ModalQueue;
