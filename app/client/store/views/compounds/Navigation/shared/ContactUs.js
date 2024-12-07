// @flow

import * as React from 'react';
import { connect } from 'react-redux';
import _ from 'lodash';
import I18n from 'store/localization';
import { MBDynamicIcon, MBGrid, MBLayout, MBLink, MBModal, MBText } from 'store/views/elements';
import { ui_actions, ui_selectors } from 'store/business/ui';
import { working_hours_selectors } from '../../../../business/working_hours';
import styles from './ContactUs.scss';
import type { WorkingHour } from '../../../../business/working_hours';
import gropedWorkingHours from '../../../../../utils/group_working_hours';

type ContactUsProps = {
  hideModal: typeof ui_actions.hideHelpModal,
  show: boolean,
  working_hours: WorkingHour
};

const ContactUs = ({ hideModal, show, working_hours }: ContactUsProps) => {
  const icon_size = 48;

  return (
    <MBModal.Modal
      show={show}
      onHide={hideModal}
      size="small"
      modalClassName={styles.cmContactUs_Modal}>
      <MBModal.SectionHeader
        renderRight={() => <MBModal.Close onClick={hideModal} />}>
        {I18n.t('ui.nav.help.header')}
      </MBModal.SectionHeader>
      <MBLayout.StandardGrid>
        <div className={styles.cmContactUs_Wrapper}>
          <MBGrid cols={1} medium_cols={2}>
            <MBGrid.Element className={styles.cmContactUs_Section_Wrapper}>
              <span className={styles.cmContactUs_Section}>
                <MBDynamicIcon className={styles.cmContactUs_Section_Icon} name="faq" color="black" height={icon_size} width={icon_size} />
                <MBText.H6 className={styles.cmContactUs_Section_Header}>{I18n.t('ui.nav.help.faqs.title')}</MBText.H6>
                <MBLink.Text target="_blank" rel="noopener noreferrer" native_behavior href="https://minibar.freshdesk.com/support/home" className={styles.cmContactUs_Section_Link}>{I18n.t('ui.nav.help.faqs.link')}</MBLink.Text>
                <MBText.Span className={styles.cmContactUs_Section_Title}>{I18n.t('ui.nav.help.faqs.info')}</MBText.Span>
              </span>
            </MBGrid.Element>
            <MBGrid.Element className={styles.cmContactUs_Section_Wrapper}>
              <span className={styles.cmContactUs_Section}>
                <MBDynamicIcon className={styles.cmContactUs_Section_Icon} name="representative" color="black" height={icon_size} width={icon_size} />
                <MBText.H6 className={styles.cmContactUs_Section_Header}>{I18n.t('ui.nav.help.customer_care.title')}</MBText.H6>
                {working_hours &&
                  gropedWorkingHours(working_hours).map(wh => {
                    return (
                      <span key={wh.startDay + wh.endDay}>
                        <MBText.Span className={styles.cmContactUs_Section_Title}>{I18n.t('ui.nav.help.customer_care.hours', { startsAt: _.toUpper(wh.startsAt), endsAt: wh.endsAt === '11:59 pm' ? 'Midnight' : _.toUpper(wh.endsAt) })}</MBText.Span><br />
                        <MBText.Span className={styles.cmContactUs_Section_Title}>{wh.startDay === wh.endDay ? I18n.t('ui.nav.help.customer_care.info', { info: wh.startDay }) : I18n.t('ui.nav.help.customer_care.info', { info: `${wh.startDay} - ${wh.endDay}` })}</MBText.Span>
                      </span>);
                  })
                }
              </span>
            </MBGrid.Element>
          </MBGrid>
          <MBText.H5 className={styles.cmContactUs_Divider}>{I18n.t('ui.nav.help.contact.headline')}</MBText.H5>
          <MBGrid cols={1} medium_cols={3}>
            <MBLink.View native_behavior href="sms:917-633-6332" className={styles.cmContactUs_Section_Button}>
              <MBGrid.Element className={styles.cmContactUs_Section_Wrapper}>
                <span className={styles.cmContactUs_Section}>
                  <MBDynamicIcon className={styles.cmContactUs_Section_Icon} name="sms" color="black" height={icon_size} width={icon_size} />
                  <MBText.H6 className={styles.cmContactUs_Section_Title}>{I18n.t('ui.nav.help.contact.text.title')}</MBText.H6>
                  <MBLink.Text>{I18n.t('ui.nav.help.contact.text.data')}</MBLink.Text>
                </span>
              </MBGrid.Element>
            </MBLink.View>
            <MBLink.View native_behavior href="mailto:help@minibardelivery.com" className={styles.cmContactUs_Section_Button}>
              <MBGrid.Element className={styles.cmContactUs_Section_Wrapper}>
                <span className={styles.cmContactUs_Section}>
                  <MBDynamicIcon className={styles.cmContactUs_Section_Icon} name="email" color="black" height={icon_size} width={icon_size} />
                  <MBText.H6 className={styles.cmContactUs_Section_Title}>{I18n.t('ui.nav.help.contact.email.title')}</MBText.H6>
                  <MBLink.Text>{I18n.t('ui.nav.help.contact.email.data')}</MBLink.Text>
                </span>
              </MBGrid.Element>
            </MBLink.View>
            <MBLink.View native_behavior href="tel:855-487-0740" className={styles.cmContactUs_Section_Button}>
              <MBGrid.Element className={styles.cmContactUs_Section_Wrapper}>
                <span className={styles.cmContactUs_Section}>
                  <MBDynamicIcon className={styles.cmContactUs_Section_Icon} name="phone" color="black" height={icon_size} width={icon_size} />
                  <MBText.H6 className={styles.cmContactUs_Section_Title}>{I18n.t('ui.nav.help.contact.phone.title')}</MBText.H6>
                  <MBLink.Text>{I18n.t('ui.nav.help.contact.phone.data')}</MBLink.Text>
                </span>
              </MBGrid.Element>
            </MBLink.View>
          </MBGrid>
        </div>
      </MBLayout.StandardGrid>
    </MBModal.Modal>
  );
};

const ContactUsSTP = (state) => ({
  show: ui_selectors.isHelpModalShowing(state),
  working_hours: working_hours_selectors.workingHours(state)
});
const ContactUsDTP = { hideModal: ui_actions.hideHelpModal };

const ContactUsContainer = connect(ContactUsSTP, ContactUsDTP)(ContactUs);

export default ContactUsContainer;
