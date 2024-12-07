// @flow

import * as React from 'react';
import I18n from 'store/localization';
import { CopyToClipboard } from 'react-copy-to-clipboard';
import styles from '../index.scss';
import { MBButton, MBText, MBIcon } from '../../../elements';


type NewUserContentProps = {|
  coupon_code: string,
  copyCoupon(code: string): void
|}

type NewUserContentState = {|
  coupon_copied: boolean
|};

class NewUserContent extends React.Component<NewUserContentProps, NewUserContentState> {
  constructor(props: NewUserContentProps){
    super(props);
    this.state = {
      coupon_copied: false
    };
  }

  renderCopyButtonContent = (copied) => {
    if (copied){
      return (
        <span>
          <MBIcon name="check" /> <span>{I18n.t('ui.email_capture_modal.new_user_content.copied')}</span>
        </span>
      );
    } else {
      return I18n.t('ui.email_capture_modal.new_user_content.copy');
    }
  };

  render(){
    return (
      <div className={styles.cmEmailCaptureModal_Content}>
        <div className={styles.cmEmailCaptureModal_NewUserContentCopy}>
          <MBText.H1 className={styles.cmEmailCaptureModal_NewUserHeadline__Large}>
            {I18n.t('ui.email_capture_modal.new_user_content.h1')}
          </MBText.H1>
          <MBText.H5 className={styles.cmEmailCaptureModal_NewUserHeadline__Small}>
            {I18n.t('ui.email_capture_modal.new_user_content.h5')}
          </MBText.H5>
          <MBText.P className={styles.cmEmailCaptureModal_NewUserContentCopy__Lowercase}>
            {I18n.t('ui.email_capture_modal.new_user_content.line_1')}<br />
            {I18n.t('ui.email_capture_modal.new_user_content.line_2_1')}
            <span className={styles.cmEmailCaptureModal_Body__BoldCaps}>
              {I18n.t('ui.email_capture_modal.new_user_content.offer')}
            </span>
            {I18n.t('ui.email_capture_modal.new_user_content.line_2_2')}
          </MBText.P>
        </div>
        <div className={styles.cmEmailCaptureModal_Coupon}>
          <MBText.Span
            className={styles.cmEmailCaptureModal_CouponCode}>{this.props.coupon_code}</MBText.Span>
          <CopyToClipboard
            text={this.props.coupon_code}
            onCopy={() => {
              this.setState({ coupon_copied: true });
              this.props.copyCoupon(this.props.coupon_code);
            }}>
            <MBButton
              className={this.state.coupon_copied ? 'cmEmailCaptureModal_CouponCopyButton__Copied' : 'cmEmailCaptureModal_CouponCopyButton'}>
              { this.renderCopyButtonContent(this.state.coupon_copied) }
            </MBButton>
          </CopyToClipboard>
        </div>
      </div>
    );
  }
}

export default NewUserContent;
