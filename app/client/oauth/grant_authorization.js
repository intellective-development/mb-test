import * as React from 'react';

const GrantAuthorizationForm = () => (
  <div className="row push-down">
    <div className="large-5 medium-5 large-centered column">
      <div className="checkout-frame oauth-page__grant-module" id="checkout-login-form">
        <h3 className="modal-header">Authorization Required</h3>
        <div className="checkout-panel">
          <div className="row form-row">
            <div className="large-12 column">
              <p>By selecting allow, you agree to provide <strong className="text-info">{Data.client_name}</strong>:</p>
              <p className="secondary">&ndash; Access to your stored Minibar Delivery account information including your name, addresses and order history.</p>
              <p className="secondary">&ndash; The ability to submit orders on your behalf using stored payment information. You will be charged for any orders placed.</p>
            </div>
          </div>
          <div className="row">
            <div className="large-12 column">
              <form action={Data.form_path} method="post">
                <input type="hidden" name="authenticity_token" value={Data.csrf_token} />
                <input type="hidden" name="client_id" value={Data.form_client_id} />
                <input type="hidden" name="redirect_uri" value={Data.form_redirect_uri} />
                <input type="hidden" name="state" value={Data.form_state} />
                <input type="hidden" name="response_type" value={Data.form_response_type} />
                <input type="hidden" name="scope" value={Data.form_scope} />
                <input type="submit" className="button expand" value="Allow" />
              </form>
              <form action={Data.form_path} method="post">
                <input type="hidden" name="_method" value="delete" />
                <input type="hidden" name="authenticity_token" value={Data.csrf_token} />
                <input type="hidden" name="client_id" value={Data.form_client_id} />
                <input type="hidden" name="redirect_uri" value={Data.form_redirect_uri} />
                <input type="hidden" name="state" value={Data.form_state} />
                <input type="hidden" name="response_type" value={Data.form_response_type} />
                <input type="hidden" name="scope" value={Data.form_scope} />
                <input type="submit" className="button secondary secondary--oauth expand" value="Deny" />
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
);

export default GrantAuthorizationForm;
