import * as React from 'react';
import Dropdown from 'react-dropdown';
import AddressEntryForm from 'oauth/delivery_address/address_entry_form';
import post from 'oauth/utils/network_requests';

class SelectDeliveryAddressForm extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      selected: false,
      enabled: false,
      processing: false,
      error: false,
      show_input_form: Data.user_addresses.length < 1
    };
  }

  handleSelect = (option) => {
    this.setState({selected: option});
    this.enableSubmit();
  };

  enableSubmit = (newState = {}) => {
    this.setState({enabled: true});
    this.setState(newState);
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

  saveAddress = () => {
    post(Data.addresses_path, {
      access_token: Data.user_token,
      client_id: Data.form_client_id,
      address_params: {
        address1: this.state.address1,
        address2: this.state.address2,
        city: this.state.city,
        state_name: this.state.state,
        zip_code: this.state.zip_code,
        phone: this.state.phone
      }
    }).error((_e) => {
      this.setState({processing: false, enabled: true, error: true});
    }).success((_e) => {
      this.props.nextStep();
    });
  };

  saveAndContinue = (e) => {
    e.preventDefault();
    this.setState({processing: true, enabled: false});

    if (this.state.show_input_form){
      this.setState({error: false});
      this.saveAddress();
    } else {
      this.props.saveValues(this.state.selected.value);
      this.props.nextStep();
    }
  };

  render(){
    return (
      <div className="row push-down">
        <div className="large-5 medium-5 large-centered column">
          <div className="checkout-frame oauth-page__grant-module" id="checkout-login-form">
            <h3 className="modal-header">Select Delivery Address</h3>
            <div className="checkout-panel">
              <div className="row form-row">
                <div className="large-12 column">
                  <p>This will be the default delivery address for orders submitted via <strong className="text-info">{Data.client_name}</strong>.</p>
                  {this.state.show_input_form ? null : <Dropdown options={Data.user_addresses} placeholder="Select a delivery address" onChange={this.handleSelect} value={this.state.selected} />}
                  {this.state.show_input_form ? null : <p className="center"><a className="secondary secondary--oauth" onClick={this.switchMode}>Add a new address</a></p>}
                  {this.state.error ? <p className="error">There was a problem saving your address, please try again.</p> : null}
                  {this.state.show_input_form ? <AddressEntryForm enableSubmit={this.enableSubmit} disableSubmit={this.disableSubmit} /> : null}
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

export default SelectDeliveryAddressForm;
