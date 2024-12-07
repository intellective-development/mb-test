import braintreeClient from 'braintree-web/client';
import braintreeHostedFields from 'braintree-web/hosted-fields';
import * as api from '@minibar/store-business/src/networking/api';

class BrainTree {
  clientTokenResponse = null;
  clientInstance = null;
  fields = {}

  async getToken(){
    if (!this.clientTokenResponse){
      this.clientTokenResponse = await api.fetchBraintreeClientToken();
    }
    return this.clientTokenResponse;
  }
  async getClient(){
    await this.getToken();
    if (!this.clientInstance){
      this.clientInstance = await braintreeClient.create({
        authorization: this.clientTokenResponse.client_token
      });
    }

    return this.clientInstance;
  }
  async renderFields({ instanceName = 'default', number = {}, cvv = {}, expirationDate = {}} = {}){
    if (this.fields[instanceName]){
      console.warn(`${instanceName} already rendered. Will be torndown and re-rendered. If you don't mean to rerender just use setters of the instance.`);
      this.fields[instanceName].teardown();
    }
    this.fields[instanceName] = await braintreeHostedFields.create({
      client: await this.getClient(),
      styles: {
        input: {
          'font-size': '15px',
          'font-family': '"Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial, sans-serif'
        }
      },
      fields: {
        number: {
          selector: '#billing_cc_number',
          ...number
        },
        cvv: {
          selector: '#billing_cc_cvc',
          placeholder: '',
          ...cvv
        },
        expirationDate: {
          selector: '#billing_cc_exp',
          placeholder: 'MM / YYYY',
          ...expirationDate
        }
      }
    });
  }
  getFieldsInstance(instanceName = 'default'){
    return this.fields[instanceName];
  }
  async tokenize({ instanceName = 'default', postalCode } = {}){
    const hostedFields = await this.getFieldsInstance(instanceName);
    if (!hostedFields){
      return Promise.reject({ message: `${instanceName} hosted fields instance isn't present. Make sure you've rendered it.` });
    }
    return hostedFields.tokenize({
      billingAddress: {
        postalCode
      }
    });
  }
}

export default new BrainTree();
