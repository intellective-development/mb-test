// @flow

import * as React from 'react';
import cn from 'classnames';
import { connect } from 'react-redux';
import { email_capture_actions, email_capture_selectors } from 'store/business/email_capture';
import I18n from 'store/localization';
import { validateEmail } from 'shared/utils/validate_contact_inputs';
import styles from './index.scss';
import {MBButton, MBDynamicIcon, MBLayout, MBInput, MBText} from '../../../elements';

type EmailCaptureSectionProps = {|
  addEmail: Function,
  onClose: Function,
  loading: boolean,
  error: string
|}

type EmailCaptureSectionState = {|
  email: string
|};

export const EMAIL_CAPTURE_SECTION_ID = 'email-capture-section-input';

class EmailCaptureSection extends React.Component<EmailCaptureSectionProps, EmailCaptureSectionState> {
  constructor(props: EmailCaptureSectionProps){
    super(props);
    this.state = {
      email: ''
    };
  }
  handleEmailChange = (event: SyntheticKeyboardEvent<HTMLInputElement>) => {
    this.setState({ email: event.currentTarget.value });
  };

  handleEmailKeyUp = (event: SyntheticKeyboardEvent<HTMLInputElement>) => {
    if (event.key !== 'Enter') return null;

    this.submitEmail();
  };

  submitEmail = () => {
    if (!validateEmail(this.state.email)) return null;

    this.props.addEmail({ email: this.state.email, target: 'Email Capture Section' });
  }

  renderErrorMessage = () => (
    <MBText.P className={styles.cmEmailCaptureSection_ErrorMessage}>{this.props.error}</MBText.P>
  );

  renderSubmitButton = () => (
    <MBButton
      className="email_capture_section__SubmitButton"
      disabled={!validateEmail(this.state.email)}
      type="action"
      size="medium"
      onClick={() => this.submitEmail()}>
      <MBDynamicIcon
        className={cn({email_capture_section__SubmitButtonIcon__Loading: this.props.loading})}
        width={25}
        height={25}
        name="right_arrow"
        color="white" />
    </MBButton>
  )
  renderInitialFormState = () => (
    <span className={styles.cmEmailCaptureSection_FormInitial}>
      <div className={styles.cmEmailCaptureSection_EmailInputWrapper}>
        <MBInput.Input
          id={EMAIL_CAPTURE_SECTION_ID}
          className={styles.cmEmailCaptureSection_EmailInput}
          type="email"
          value={this.state.email}
          placeholder={I18n.t('ui.email_capture_section.form.email')}
          onChange={this.handleEmailChange}
          onKeyUp={this.handleEmailKeyUp} />
        {this.props.error ? this.renderErrorMessage() : null}
      </div>
      {this.renderSubmitButton()}
    </span>
  )

  renderSuccessMessage = () => {
    if (this.props.status === 'new_user'){
      return (
        <span>
          {I18n.t('ui.email_capture_section.new_user.beginning')}
          <span className={styles.cmEmailCaptureSection_FormSuccessCode}>{I18n.t('ui.email_capture_section.new_user.code')}</span>
          {I18n.t('ui.email_capture_section.new_user.end')}
        </span>
      );
    } else if (this.props.status === 'existing_user'){
      return (
        I18n.t('ui.email_capture_section.existing_user.message')
      );
    } else {
      return null;
    }
  }

  renderSubmittedFormState = () => (
    <span className={styles.cmEmailCaptureSection_FormSuccess}>
      <MBDynamicIcon className={styles.cmEmailCaptureSection_FormSuccessIcon} name="check" width={36} height={36} />
      <MBText.P className={styles.cmEmailCaptureSection_FormSuccessMessage}>
        {this.renderSuccessMessage()}
      </MBText.P>
    </span>
  );

  render(){
    return (
      <div className={styles.cmEmailCaptureSectionWrapper}>
        <MBLayout.StandardGrid className={styles.cmEmailCaptureSection}>
          <span className={styles.cmEmailCaptureSection_Offer}>
            <MBText.H2 className={styles.cmEmailCaptureSection_OfferHeadline}>{I18n.t('ui.email_capture_section.offer.headline')}</MBText.H2>
            <span className={styles.cmEmailCaptureSection_OfferBody}>
              <MBDynamicIcon name="email" width={25} height={25} color="white" className={styles.cmEmailCaptureSection_OfferBodyIcon} />
              <MBText.P className={styles.cmEmailCaptureSection_OfferCopy}>
                {I18n.t('ui.email_capture_section.offer.copy')}
              </MBText.P>
            </span>
          </span>
          {this.props.status === 'initial' ? this.renderInitialFormState() : this.renderSubmittedFormState()}
        </MBLayout.StandardGrid>
      </div>
    );
  }
}

const EmailCaptureSectionSTP = (state) => ({
  loading: email_capture_selectors.isLoading(state),
  status: email_capture_selectors.modalStatus(state),
  error: email_capture_selectors.error(state)
});

const EmailCaptureSectionDTP = {
  showModal: email_capture_actions.showModal,
  addEmail: email_capture_actions.addEmail
};

const EmailCaptureSectionContainer = connect(EmailCaptureSectionSTP, EmailCaptureSectionDTP)(EmailCaptureSection);

export default EmailCaptureSectionContainer;
