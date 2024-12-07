import * as React from 'react';
import _ from 'lodash';
import Geosuggest from 'react-geosuggest';
import getComponentShortName from 'oauth/utils/google_places';

const fields = ['address1', 'city', 'state', 'zip_code', 'phone'];

class AddressEntryForm extends React.Component {
  constructor(props){
    super(props);
    this.state = {
      address1: '',
      address2: '',
      city: '',
      state: '',
      zip_code: ''
    };
  }

  addressSelected = (suggest) => {
    const addressObject = {};
    const components = suggest.gmaps.address_components;

    addressObject.address1 = `${getComponentShortName(components, 'street_number')} ${getComponentShortName(components, 'route')}`;
    addressObject.city = getComponentShortName(components, 'locality') || getComponentShortName(components, 'sublocality');
    addressObject.state = getComponentShortName(components, 'administrative_area_level_1');
    addressObject.zip_code = getComponentShortName(components, 'postal_code');

    this.setState(addressObject);
    this.validate();
  };

  isValid = () => {
    const errors = {};

    fields.forEach((field) => {
      const value = this.state[field];
      if (!value){
        errors[field] = 'The field is required';
      }
    });

    this.setState({errors: errors});

    const is_valid = _.isEmpty(errors);
    return is_valid;
  };

  handleChange = (field, e) => {
    const field_val = e.target.value;
    this.setState({[field]: field_val});
    this.validate();
  };

  validate = () => {
    if (this.isValid()){
      this.props.enableSubmit(this.state);
    } else {
      this.props.disableSubmit();
    }
  };

  render(){
    const types = ['geocode'];

    return (
      <div id="address-entry__fields">
        <div className="row">
          <div className="small-12 column">
            <Geosuggest autofocus placeholder="Type an address" country="us" types={types} onSuggestSelect={this.addressSelected} />
          </div>
        </div>
        <div className="row">
          <div className="small-6 column">
            <label>
              Apt/Floor
              <input type="text" name="address2" onChange={this.handleChange.bind(this, 'address2')} onBlur={this.handleChange.bind(this, 'address2')} />
            </label>
          </div>
          <div className="small-6 column">
            <label>
              Phone Number
              <input type="tel" name="phone" onChange={this.handleChange.bind(this, 'phone')} onBlur={this.handleChange.bind(this, 'phone')} pattern="\d*" />
            </label>
          </div>
        </div>
      </div>
    );
  }
}

export default AddressEntryForm;
