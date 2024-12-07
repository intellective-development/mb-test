// @flow

import braintree_client from 'braintree-web/client';

type CardData = {
  number: string,
  expirationMonth: string,
  expirationYear: string,
  cvv: string,
  billingAddress: {
    postalCode: string
  }
}
type TokenizeOptions = {
  braintree_client_token: string
}

const BRAINTREE_ERROR_BODY = {message: 'Invalid Credit Card'};
export const tokenizeCard = (card_data: CardData, {braintree_client_token}: TokenizeOptions): Promise<string> => {
  const tokenize_card_prom = new Promise((resolve, reject) => {
    braintree_client.create(
      { authorization: braintree_client_token },
      (create_error, client_instance) => {
        if (create_error){
          if (global.Raven) global.Raven.captureMessage(create_error);
          reject({error: BRAINTREE_ERROR_BODY});
          return null;
        }
        return client_instance.request({
          endpoint: 'payment_methods/credit_cards',
          method: 'post',
          data: { creditCard: card_data, options: { validate: false } }
        }, (request_error, response) => {
          if (request_error){
            if (global.Raven) global.Raven.captureMessage(request_error);
            reject({error: BRAINTREE_ERROR_BODY});
          } else {
            const nonce = response.creditCards[0].nonce;
            resolve(nonce);
          }
        });
      }
    );
  });

  return tokenize_card_prom;
};
