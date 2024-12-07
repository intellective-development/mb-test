// @flow

import * as React from 'react';
import bindClassNames from 'shared/utils/bind_classnames';
import I18n from 'store/localization';

import { MBLink, MBText } from '../../elements';
import styles from './index.scss';

const cn = bindClassNames(styles);

type AgeTermsWarningProps = {className?: string};
const AgeTermsWarning = ({className}: AgeTermsWarningProps) => (
  <MBText.P className={cn('cmAgeTerms', className)}>
    {I18n.t('ui.body.age_terms.age')}
    <MBLink.Text
      href="/terms"
      target="_blank"
      rel="noopener noreferrer"
      native_behavior> {I18n.t('ui.body.age_terms.terms')}</MBLink.Text>
  </MBText.P>
);

export default AgeTermsWarning;
