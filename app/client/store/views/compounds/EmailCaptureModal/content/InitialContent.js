// @flow

import * as React from 'react';
import I18n from 'store/localization';
import { validateEmail } from 'shared/utils/validate_contact_inputs';
import styles from '../index.scss';
import { MBButton, MBInput, MBText } from '../../../elements';


type InitialContentProps = {|
  onSubmit: Function,
  onClose: Function,
  loading: boolean,
  error: string
|}

type InitialContentState = {|
  email: string
|};

class InitialContent extends React.Component<InitialContentProps, InitialContentState> {
  constructor(props: InitialContentProps){
    super(props);
    this.state = {
      email: ''
    };
  }

  emailInput: ?HTMLInputElement

  handleChange = (e) => {
    this.setState({ email: e.target.value });
  };

  componentDidMount(){
    setTimeout(() => this.emailInput && this.emailInput.focus(), 0); // Input doesn't focus without Timeout.
  }

  render(){
    return (
      <div>
        <div className={styles.cmEmailCaptureModal_Content}>
          <MBText.H5 className={styles.cmEmailCaptureModal_Headline__Small}>
            {I18n.t('ui.email_capture_modal.initial_content.h5')}
          </MBText.H5>
          <MBText.H1 className={styles.cmEmailCaptureModal_Headline__Large}>
            {I18n.t('ui.email_capture_modal.initial_content.h1')}<br />
          </MBText.H1>
          <MBText.P className={styles.cmEmailCaptureModal_Body__Large}>
            {I18n.t('ui.email_capture_modal.initial_content.line_1')}
          </MBText.P>
          <MBText.P className={styles.cmEmailCaptureModal_Body__Small}>
            {I18n.t('ui.email_capture_modal.initial_content.line_2')}
          </MBText.P>
        </div>
        <div className={styles.cmEmailCaptureModal_Form}>
          <MBText.Span className={styles.cmEmailCaptureModal_ValidationErrorMessage}>{this.props.error}</MBText.Span>
          <MBInput.Input
            className={this.props.error ? 'cmEmailCaptureModal_TextField__Error' : 'cmEmailCaptureModal_TextField'}
            type="email"
            inputRef={(input) => { this.emailInput = input; }}
            tabIndex="-1"
            value={this.state.email}
            placeholder="Enter your email address"
            onChange={this.handleChange} />
          <MBButton
            className={styles.cmEmailCaptureModal_SubmitButton}
            disabled={!validateEmail(this.state.email) || this.props.loading}
            expand
            onClick={() => this.props.onSubmit(this.state.email)}>
            { this.props.loading ? I18n.t('ui.email_capture_modal.initial_content.loading') : I18n.t('ui.email_capture_modal.initial_content.join') }
          </MBButton>
        </div>
        <MBText.P
          className={styles.cmEmailCaptureModal_Link}
          onClick={() => this.props.onClose()}
          role="button"
          tabIndex="-1">
          {I18n.t('ui.email_capture_modal.initial_content.no_thanks')}
        </MBText.P>
      </div>
    );
  }
}

export default InitialContent;
