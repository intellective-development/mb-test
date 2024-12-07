// @flow

import * as React from 'react';
import i18n from 'store/localization';
import styles from './index.scss';
import { MBAppStoreLink, MBLayout, MBText } from '../../../elements';

const AppInstallSection = () => {
  return (
    <MBLayout.StandardGrid className={styles.cmAppInstallSection_Wrapper}>
      <img
        alt={i18n.t('ui.app_install_section.image_alt_text')}
        className={styles.cmAppInstallSection_Image}
        src={'/assets/components/elements/app-install-section/app_install_image.jpg'}
        srcSet={'/assets/components/elements/app-install-section/app_install_image@2x.jpg 2x, ' +
                  '/assets/components/elements/app-install-section/app_install_image@3x.jpg 3x'} />
      <div className={styles.cmAppInstallSection_CopyWrapper}>
        <MBText.H1 className={styles.cmAppInstallSection_Headline}>{i18n.t('ui.app_install_section.headline')}</MBText.H1>
        <MBText.P className={styles.cmAppInstallSection_Body}>
          {i18n.t('ui.app_install_section.copy')}
        </MBText.P>
        <MBAppStoreLink className={styles.cmAppInstallSection_App_Icons} />
      </div>
    </MBLayout.StandardGrid>
  );
};

export default AppInstallSection;
