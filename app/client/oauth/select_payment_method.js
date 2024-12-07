// @flow

import * as React from 'react';
import Dropdown from 'react-dropdown';
import PaymentEntryForm from 'oauth/delivery_address/payment_entry_form';
import post from 'oauth/utils/network_requests';
import { payment_profile_utils } from '../store/business/payment_profile';

type SelectPaymentFormProps = {|
  saveValues: (any) => void,
  nextStep: () => void
|}

type SelectPaymentFormState = {|
  selected: boolean,
  enabled: boolean,
  show_input_form: boolean,
  error: boolean,
  processing: boolean
|}

class SelectPaymentMethodForm extends React.Component<SelectPaymentFormProps, SelectPaymentFormState> {
  payment_entry_form: ?React.Ref<typeof PaymentEntryForm>

  constructor(props){
    super(props);
    this.state = {
      selected: false,
      enabled: false,
      show_input_form: Data.user_payment_profiles.length < 1,
      error: false,
      processing: false
    };
  }

  handleSelect = (option) => {
    this.setState({selected: option });
    this.enableSubmit();
  };

  enableSubmit = () => {
    this.setState({enabled: true});
  };

  disableSubmit = () => {
    this.setState({enabled: false});
  };

  switchMode = (e) => {
    e.preventDefault();
    this.setState({
      show_input_form: true
    });
  };

  savePaymentMethod = () => {
    const token_data = {
      number: this.payment_entry_form.refs.card_container.refs.number.value,
      expirationDate: this.payment_entry_form.refs.card_container.refs.expiry.value.replace(/\s/g, ''),
      cardholderName: this.payment_entry_form.refs.card_container.refs.name.value,
      cvv: this.payment_entry_form.refs.card_container.refs.cvc.value,
      billingAddress: {
        postalCode: this.payment_entry_form.refs.card_container.refs.zip_code.value
      }
    };

    payment_profile_utils
      .tokenizeCard(token_data, {braintree_client_token: Data.braintree_client_token})
      .then(this.handleBraintreeSuccess, this.handleBraintreeError);
  };

  handleBraintreeSuccess = (nonce) => {
    post(Data.payment_methods_path, {
      access_token: Data.user_token,
      client_id: Data.form_client_id,
      payment_method_nonce: nonce,
      name: this.payment_entry_form.refs.card_container.refs.name.value,
      zip_code: this.payment_entry_form.refs.card_container.refs.zip_code.value
    }).error(this.handleBraintreeError).success(() => this.props.nextStep());
  };

  handleBraintreeError = (_error) => {
    this.setState({error: true, processing: false, enabled: true});
  };

  saveAndContinue = (e) => {
    e.preventDefault();
    this.setState({processing: true, enabled: false});

    if (this.state.show_input_form){
      this.setState({error: false});
      this.savePaymentMethod();
    } else {
      this.props.saveValues(this.state.selected.value);
      this.props.nextStep();
    }
  };


  renderFormContent = () => {
    if (this.state.show_input_form){
      return (
        <PaymentEntryForm
          ref={(el) => { this.payment_entry_form = el; }}
          enableSubmit={this.enableSubmit}
          disableSubmit={this.disableSubmit} />
      );
    } else {
      return (
        <div>
          <Dropdown
            options={Data.user_payment_profiles}
            placeholder="Select a payment method"
            onChange={this.handleSelect}
            value={this.state.selected} />
          <p className="center">
            <a
              className="secondary secondary--oauth"
              role="button"
              tabIndex="-1"
              onClick={this.switchMode}>Add a new payment method</a>
          </p>
        </div>
      );
    }
  }

  render(){
    return (
      <div className="row push-down">
        <div className="large-5 medium-5 large-centered column">
          <div className="checkout-frame oauth-page__grant-module" id="checkout-login-form">
            <h3 className="modal-header">Select Payment Method</h3>
            <div className="checkout-panel">
              <div className="row form-row">
                <div className="large-12 column">
                  <p>This will be the default payment method for orders submitted via <strong className="text-info">{Data.client_name}</strong>.</p>
                  {this.renderFormContent()}
                  {this.state.error ? <p className="error">We were unable to verify your credit card, please verify the billing details and try again.</p> : null}
                </div>
              </div>
              <div className="row">
                <div className="large-12 column">
                  <button className="button expand last" onClick={this.saveAndContinue} disabled={!this.state.enabled}>{this.state.processing ? 'Processing' : 'Continue'}</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

export default SelectPaymentMethodForm;
