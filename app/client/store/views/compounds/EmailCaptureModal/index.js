// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import { email_capture_actions, email_capture_selectors } from 'store/business/email_capture';
import { EMAIL_CAPTURE_COOKIE_NAME, EMAIL_MODAL_DELAY, SHORT_LIVED_COOKIE_LIFESPAN, LONG_LIVED_COOKIE_LIFESPAN } from 'store/business/email_capture/constants';
import styles from './index.scss';
import AddEventListeners from './AddEventListeners';
import { InitialContent, NewUserContent, ExistingUserContent } from './content';
import { MBIcon, MBModal } from '../../elements';
import * as mb_cookie from '../../../business/utils/mb_cookie';


type EmailCaptureModalProps = {|
  status: string,
  should_show: boolean,
  is_showing: boolean,
  loading: boolean,
  error: string,
  hideModal: Function,
  showModal: Function,
  addEmail: Function
|};


class EmailCaptureModal extends React.Component<EmailCaptureModalProps> {
  show_modal_timeout: number

  componentDidMount(){
    this.show_modal_timeout = setTimeout(this.showModalIfShould, EMAIL_MODAL_DELAY);
  }

  componentWillUnmount(){
    clearTimeout(this.show_modal_timeout);
  }

  showModalIfShould = () => {
    const { should_show, showModal } = this.props;
    if (should_show){ showModal(); }
  }

  setModalViewedCookie = (cookie_lifespan) => {
    mb_cookie.set(EMAIL_CAPTURE_COOKIE_NAME, true, {expires: cookie_lifespan});
  };

  onHideModal = (target) => {
    this.props.hideModal(target);
    const cookie_lifespan = this.props.status === 'initial' ? SHORT_LIVED_COOKIE_LIFESPAN : LONG_LIVED_COOKIE_LIFESPAN;
    this.setModalViewedCookie(cookie_lifespan);
  };

  renderContent = () => {
    const { status, loading, error, addEmail, copyCoupon } = this.props;
    switch (status){
      case 'new_user':
        return <NewUserContent coupon_code="welcome" copyCoupon={copyCoupon} />;
      case 'existing_user':
        return (
          <ExistingUserContent
            onClose={() => {
              this.onHideModal('continue_shopping');
            }} />
        );
      case 'initial':
      default:
        return (
          <InitialContent
            onClose={() => {
              this.onHideModal('no_thanks');
            }}
            onSubmit={(email) => addEmail({ email, target: 'Email Capture Modal'})}
            loading={loading}
            error={error} />
        );
    }
  }

  render(){
    const { is_showing } = this.props;
    return (
      <React.Fragment>
        <MBModal.Modal
          modalClassName="cmEmailCaptureModal"
          show={is_showing}
          onHide={() => {
            this.onHideModal('off_screen_or_escape');
          }}
          size="small">
          <div className={styles.cmEmailCaptureModal_ContentWrapper}>
            <MBIcon
              name="close"
              className={styles.cmEmailCaptureModal_CloseButton}
              onClick={() => {
                this.onHideModal('close_button');
              }}
              role="button"
              tabIndex="-1"
              id="close_button" />
            {this.renderContent()}
          </div>
        </MBModal.Modal>
        <AddEventListeners />
      </React.Fragment>
    );
  }
}

const EmailCaptureModalSTP = (state) => ({
  should_show: email_capture_selectors.shouldShowModal(state),
  is_showing: email_capture_selectors.isModalShowing(state),
  loading: email_capture_selectors.isLoading(state),
  status: email_capture_selectors.modalStatus(state),
  error: email_capture_selectors.error(state)
});

const EmailCaptureModalDTP = {
  hideModal: email_capture_actions.hideModal,
  showModal: email_capture_actions.showModal,
  addEmail: email_capture_actions.addEmail,
  copyCoupon: email_capture_actions.copyCoupon
};

const EmailCaptureModalContainer = connect(EmailCaptureModalSTP, EmailCaptureModalDTP)(EmailCaptureModal);

export default EmailCaptureModalContainer;
