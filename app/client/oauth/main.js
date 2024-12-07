import * as React from 'react';
import SelectDeliveryAddressForm from 'oauth/select_delivery_address';
import SelectPaymentMethodForm from 'oauth/select_payment_method';
import GrantAuthorizationForm from 'oauth/grant_authorization';
import post from 'oauth/utils/network_requests';

class AuthorizationFlow extends React.Component {
  state = {
    step: Data.initial_state
  };

  saveAddress = (id) => {
    post(Data.defaults_path, {
      access_token: Data.user_token,
      type: 'address',
      resource_id: id,
      client_id: Data.form_client_id
    });
  };

  savePaymentProfile = (id) => {
    post(Data.defaults_path, {
      access_token: Data.user_token,
      type: 'payment_profile',
      resource_id: id,
      client_id: Data.form_client_id
    });
  };

  nextStep = () => {
    this.setState({
      step: this.state.step + 1
    });
  };

  render(){
    switch (this.state.step){
      case 1:
        return (
          <SelectDeliveryAddressForm
            {...this.state}
            nextStep={this.nextStep}
            saveValues={this.saveAddress} />
        );
      case 2:
        return (
          <SelectPaymentMethodForm
            {...this.state}
            nextStep={this.nextStep}
            saveValues={this.savePaymentProfile} />
        );
      case 3:
        return <GrantAuthorizationForm {...this.state} />;
      default:
        return <GrantAuthorizationForm {...this.state} />;
    }
  }
}

export default AuthorizationFlow;
