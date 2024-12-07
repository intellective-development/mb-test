import * as React from 'react';
import _ from 'lodash';
/*global Payment */
import ReactCardFormContainer from 'card-react';

const fields = ['number', 'cvc', 'expiry', 'name', 'zip_code'];

class PaymentEntryForm extends React.Component {
  state = {};

  componentDidMount(){
    Payment.restrictNumeric(this.refs.card_container.refs.zip_code);
  }

  isValid = () => {
    const errors = {};

    fields.forEach((field) => {
      const value = this.state[field];
      if (!value){
        errors[field] = 'The field is required';
      }
    });

    const is_valid = _.isEmpty(errors);
    return is_valid;
  }

  handleChange = (_field, _e) => {
    const nextState = {};

    fields.forEach((field) => {
      const cardField = this.refs.card_container.refs[field];
      if (cardField.className.indexOf('error') === -1){
        nextState[field] = cardField.value;
      }
    });

    this.setState(nextState);
    this.validate();
  }

  validate = () => {
    if (this.isValid()){
      this.props.enableSubmit(this.state);
    } else {
      this.props.disableSubmit();
    }
  }

  render(){
    return (
      <div id="payment-entry__fields">
        <div id="card-wrapper" />
        <ReactCardFormContainer
          ref="card_container"
          container="card-wrapper"
          classes={{
            valid: 'valid-input',
            invalid: 'error'
          }}
          formatting >
          <form>
            <input ref="name" placeholder="Full name" type="text" name="name" maxLength="30" onChange={() => this.handleChange('name')} onBlur={() => this.handleChange('name')} />
            <input ref="number" placeholder="Card number" type="text" name="number" maxLength="20" pattern="[0-9]*" onChange={() => this.handleChange('number')} onBlur={() => this.handleChange('number')} />
            <input ref="expiry" placeholder="MM/YY" type="text" name="expiry" pattern="[0-9]*" onChange={() => this.handleChange('expiry')} onBlur={() => this.handleChange('expiry')} />
            <input ref="cvc" placeholder="CVC" type="text" name="cvc" autoComplete="off" maxLength="4" pattern="[0-9]*" onChange={() => this.handleChange('cvc')} onBlur={() => this.handleChange('cvc')} />
            <input ref="zip_code" placeholder="Billing Zip Code" type="text" name="zip_code" maxLength="5" pattern="[0-9]*" onChange={() => this.handleChange('zip_code')} onBlur={() => this.handleChange('zip_code')} />
          </form>

        </ReactCardFormContainer>
      </div>
    );
  }
}

export default PaymentEntryForm;
