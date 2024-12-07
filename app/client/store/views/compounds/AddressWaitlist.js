// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import * as Ent from '@minibar/store-business/src/utils/ent';
import type { Address } from 'store/business/address';
import { address_actions, address_selectors } from 'store/business/address';

import { MBText, MBButton, MBInput, MBModal, MBLayout } from '../elements';

type AddressWaitlistProps = {
  hideModal: Function,
  routeBack?: Function,

  // HOC props
  waitlisted_address: ?Address,
  joinWaitlist: Function
}
type AddressWaitlistState = {submitted: boolean, email: string};
class AddressWaitlist extends React.Component<AddressWaitlistProps, AddressWaitlistState> {
  state = {submitted: false, email: ''};

  updateEmail = (event: SyntheticInputEvent) => {
    this.setState({email: event.target.value});
  }

  joinWaitlist = () => {
    this.props.joinWaitlist(this.state.email, this.props.waitlisted_address);

    // we eager update, acting as if the waitlist submission was a success
    this.setState({submitted: true});
  }

  render(){
    const { hideModal, routeBack } = this.props;
    const { email, submitted } = this.state;

    // switch between the input and thank you based on whether or not the user has submitted their email
    let cta_content;
    if (!submitted){
      cta_content = <AddressWaitlistInput email={email} onChange={this.updateEmail} onSubmit={this.joinWaitlist} />;
    } else {
      cta_content = <AddressWaitlistThankYou />;
    }

    // only render the appropriate header elements if we have routing actions for them
    let header_render_props = {};
    if (routeBack) header_render_props = {...header_render_props, renderLeft: () => <MBModal.Back onClick={routeBack} />};
    if (hideModal) header_render_props = {...header_render_props, renderRight: () => <MBModal.Close onClick={hideModal} />};

    return (
      <div>
        <MBModal.SectionHeader {...header_render_props}>
          Outside of Service Area
        </MBModal.SectionHeader>
        <div className="cm-ae-modal__body">
          <MBText.H4 className="cm-ae-modal__heading">{'Unfortunately, we don\'t serve your address yet!'}</MBText.H4>
          <MBText.H5 className="cm-ae-modal__subheading">
            {'But enter your email address and we\'ll let you know when we expand to your area.'}
          </MBText.H5>
          {cta_content}
        </div>
      </div>
    );
  }
}
const AddressWaitlistSTP = () => {
  const findAddress = Ent.find('address');
  return (state) => ({
    waitlisted_address: findAddress(state, address_selectors.outsideServiceAreaAddressId(state))
  });
};
const AddressWaitlistDTP = {joinWaitlist: address_actions.joinWaitlist};
const AddressWaitlistContainer = connect(AddressWaitlistSTP, AddressWaitlistDTP)(AddressWaitlist);

const AddressWaitlistInput = ({email, onChange, onSubmit}) => (
  <MBLayout.ButtonInput className="cm-ae-waitlist__input__container">
    <MBInput.Input
      type="email"
      placeholder="Enter your email address"
      value={email}
      onChange={onChange}
      autoComplete="false" />
    <MBButton onClick={onSubmit}>Submit</MBButton>
  </MBLayout.ButtonInput>
);

const AddressWaitlistThankYou = () => (
  <MBText.P className="cm-ae-modal__subheading">Thanks! We will be in touch soon.</MBText.P>
);

// also export this, it's used in a few places
type AddressWaitlistModalProps = {isHidden: boolean, hideModal: Function};
export const AddressWaitlistModal = ({isHidden, hideModal}: AddressWaitlistModalProps) => {
  return (
    <MBModal.Modal show={!isHidden} onHide={hideModal}>
      <AddressWaitlistContainer hideModal={hideModal} />
    </MBModal.Modal>
  );
};

export default AddressWaitlistContainer;
