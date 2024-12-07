// @flow

import * as React from 'react';
import m from 'moment';
import {connect} from 'react-redux';
import {email_capture_selectors} from 'store/business/email_capture';
import {EMAIL_MODAL_DELAY} from 'store/business/email_capture/constants';
import styles from './index.scss';
import {MBIcon, MBModal, MBButton} from '../../elements';


type PopupModalProps = {|
  status: string,
  should_show: boolean,
  is_showing: boolean,
  loading: boolean,
  error: string,
|};

const popupMarkItemName = 'popup';

class PopupModal extends React.Component<PopupModalProps> {
  state = {
    email: {},
    open: false
  }

  componentDidMount = () => {
    this.show_modal_timeout = setTimeout(this.showModalIfShould, EMAIL_MODAL_DELAY);
  }

  componentWillUnmount(){
    clearTimeout(this.show_modal_timeout);
  }

  showModal = () => {
    this.setState({ open: true });
  }

  hideModal = () => {
    this.setState({ open: false });
  }

  showModalIfShould = () => {
    const popupMark = localStorage.getItem(popupMarkItemName);
    const popupMarkDate = m(popupMark);
    const difference = m().diff(popupMarkDate, 'days');
    const shouldShow = (isNaN(difference) || difference >= 1) && window.PopupBanner;
    if (shouldShow){ this.showModal(); }
  }

  setModalViewedCookie = () => {
    localStorage.setItem(popupMarkItemName, m());
  };

  onHideModal = () => {
    this.hideModal();
    this.setModalViewedCookie();
  };

  render(){
    const { open } = this.state;
    return (
      <React.Fragment>
        <MBModal.Modal
          modalClassName="cmEmailCaptureModal"
          show={open}
          onHide={this.onHideModal}
          size="small">
          <div className={styles.cmEmailCaptureModal_ContentWrapper}>
            <MBIcon
              name="close"
              className={styles.cmEmailCaptureModal_CloseButton}
              onClick={this.onHideModal}
              role="button"
              tabIndex="-1"
              id="close_button" />
            <div>
              <div className="text-center" dangerouslySetInnerHTML={{ __html: window.PopupBanner }} />
              <div className={`${styles.cmEmailCaptureModal_Form} text-center`}>
                <MBButton
                  className={styles.cmEmailCaptureModal_SubmitButton}
                  onClick={this.onHideModal}>
                  Start shopping
                </MBButton>
              </div>
            </div>
          </div>
        </MBModal.Modal>
      </React.Fragment>
    );
  }
}

const PopupModalSTP = (state) => ({
  should_show: true,
  is_showing: true,
  loading: false,
  isEmailShowing: email_capture_selectors.isModalShowing(state),
  shouldShowEmail: email_capture_selectors.shouldShowModal(state)
});

const PopupModalContainer = connect(PopupModalSTP)(PopupModal);

export default PopupModalContainer;
