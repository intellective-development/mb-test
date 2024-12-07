// @flow

import * as React from 'react';
import I18n from 'store/localization';
import styles from '../index.scss';
import { MBText } from '../../../elements';

type ExistingUserContentProps = {|
  onClose: Function
|};

const ExistingUserContent = ({ onClose }: ExistingUserContentProps) => (
  <div className={styles.cmEmailCaptureModal_Content}>
    <div className={styles.cmEmailCaptureModal_ExistingUserContentCopy}>
      <MBText.H1 className={styles.cmEmailCaptureModal_ExistingUserHeadline__Large}>
        {I18n.t('ui.email_capture_modal.existing_user_content.h1')}
      </MBText.H1>
      <MBText.H5 className={styles.cmEmailCaptureModal_ExistingUserHeadline__Small}>
        {I18n.t('ui.email_capture_modal.existing_user_content.h5_line_1')}<br />
        {I18n.t('ui.email_capture_modal.existing_user_content.h5_line_2')}
      </MBText.H5>
    </div>
    <MBText.P
      className={styles.cmEmailCaptureModal_Link}
      onClick={() => onClose()}
      role="button"
      tabIndex="-1">
      {I18n.t('ui.email_capture_modal.existing_user_content.continue_shopping')}
    </MBText.P>
  </div>
);

export default ExistingUserContent;
