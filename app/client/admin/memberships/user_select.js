import PropTypes from 'prop-types';
import * as React from 'react';
import VirtualizedSelect from 'react-virtualized-select';
import StaticSelect from 'admin/select_components/static_select';
import {
  fetchUsers,
  fetchPaymentProfiles
} from 'admin/admin_api';

class UserModule extends React.Component {
  static propTypes = {
    initialValues: PropTypes.array,
    name: PropTypes.string,
    type: PropTypes.string,
    label: PropTypes.string,
    couponId: PropTypes.number
  };

  constructor(props){
    super(props);
    this.state = { selectedValues: this.props.initialValues, paymentProfiles: [] };
  }

  componentDidMount(){
    this.updatePaymentProfiles(this.state.selectedValues)
  }

  onUserChange = (userSelect) => {
    this.updatePaymentProfiles([userSelect])
  };

  onPaymentProfileChange = (paymentProfileSelect) => {
    if (!this.state.selectedValues || !this.state.selectedValues.length) return;

    this.state.selectedValues[1] = paymentProfileSelect;
    this.updatePaymentProfiles(this.state.selectedValues);
  };

  updatePaymentProfiles(selectedValues) {
    if (!selectedValues || !selectedValues.length) return;
    
    fetchPaymentProfiles(selectedValues[0].value).then((data) => {
      this.setState({ selectedValues: selectedValues, paymentProfiles: data });
    });
  }

  currentUserValues() {
    if (!this.state.selectedValues || !this.state.selectedValues.length) return;

    return this.state.selectedValues[0];
  }

  currentPaymentProfileValues() {
    if (!this.state.selectedValues || !this.state.selectedValues.length) return;

    return this.state.selectedValues[1];
  }

  render() {
    return (
      <div className="row">
        <div className="large-6 columns">
          <label htmlFor={`async-select_${this.props.type}`}>
            <label>{this.props.label}</label>
            <VirtualizedSelect
              async
              id={`async-select_${this.props.type}`}
              loadOptions={fetchUsers}
              onChange={this.onUserChange}
              name={this.props.name}
              placeholder={this.props.placeholder}
              value={this.currentUserValues()}
            />
          </label>
        </div>
        <div className="large-6 columns">
          <StaticSelect
            options={this.state.paymentProfiles}
            name={'membership[payment_profile_id]'}
            onChange={this.onPaymentProfileChange}
            label={'Payment Profile'}
            value={this.currentPaymentProfileValues()}/>
        </div>
      </div>
    );
  }
}

export default UserModule;
