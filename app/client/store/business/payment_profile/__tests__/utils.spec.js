/* eslint import/first: 0 */
jest.mock('braintree-web/client');

import braintree_client from 'braintree-web/client';
import { tokenizeCard } from '../utils';

describe('tokenizeCard', () => {
  const tokenize_options = {braintree_client_token: 'abc123'};
  const braintree_card_data = {
    number: '4111111111111111',
    expirationMonth: '08',
    expirationYear: '20',
    cvv: '123',
    billingAddress: {
      postalCode: '12345'
    }
  };

  it('returns a promise containing the nonce when the client instantiation and request both succeed', () => {
    const stubbed_nonce = 'abc123';
    const stubbed_client_instance = braintree_client.__createClientInstance({
      response: { creditCards: [{nonce: stubbed_nonce}] },
      request_error: null
    });
    braintree_client.__doCreate.mockReturnValue({
      client_instance: stubbed_client_instance,
      create_error: null
    });

    expect.hasAssertions();
    return tokenizeCard(braintree_card_data, tokenize_options).then(nonce => {
      expect(nonce).toEqual(stubbed_nonce);
      expect(braintree_client.create).toHaveBeenCalledWith(
        {authorization: tokenize_options.braintree_client_token},
        expect.any(Function)
      );
      expect(stubbed_client_instance.request).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            creditCard: braintree_card_data,
            options: {validate: false}
          }
        }),
        expect.any(Function)
      );
    });
  });

  it('returns a rejected promise containing the error when the client request fails', () => {
    const stubbed_error = 'Credit Card is Invalid';
    const stubbed_client_instance = braintree_client.__createClientInstance({
      response: null,
      request_error: stubbed_error
    });
    braintree_client.__doCreate.mockReturnValue({
      client_instance: stubbed_client_instance,
      create_error: null
    });

    expect.hasAssertions();
    return tokenizeCard(braintree_card_data, tokenize_options).catch(error => {
      expect(error).toEqual({error: {message: 'Invalid Credit Card'}});
      expect(braintree_client.create).toHaveBeenCalledWith(
        {authorization: tokenize_options.braintree_client_token},
        expect.any(Function)
      );
      expect(stubbed_client_instance.request).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            creditCard: braintree_card_data,
            options: {validate: false}
          }
        }),
        expect.any(Function)
      );
    });
  });

  it('returns a rejected promise containing the error when the client instantiation fails', () => {
    const stubbed_error = 'Cannot create braintree client';
    braintree_client.__doCreate.mockReturnValue({
      client_instance: null,
      create_error: stubbed_error
    });

    expect.hasAssertions();
    return tokenizeCard(braintree_card_data, tokenize_options).catch(error => {
      expect(error).toEqual({error: {message: 'Invalid Credit Card'}});
      expect(braintree_client.create).toHaveBeenCalledWith(
        {authorization: tokenize_options.braintree_client_token},
        expect.any(Function)
      );
    });
  });
});
