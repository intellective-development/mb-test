import React from 'react';
import I18n from 'store/localization';
import { MBText, MBTooltip } from '../../elements';
import styles from './index.scss';


const AddressExplanation = () => (
  <span className={styles.cmAddressExplanation_Container}>
    <MBText.Span className={styles.cmAddressExplanation_Text}>
      {I18n.t('ui.body.landing_hero.address_explanation_short')}
    </MBText.Span>
    <MBTooltip
      default_orientation="bottom"
      tooltip_text={I18n.t('ui.body.landing_hero.address_explanation_long')}>
      <MBText.Span className={styles.cmAddressExplanation_TooltipPrompt}>
        {I18n.t('ui.body.landing_hero.address_explanation_long_prompt')}
      </MBText.Span>
    </MBTooltip>
  </span>
);

export default AddressExplanation;
