import { __private__ } from '../session_auth_api';

const { formatSessionEndpointError } = __private__;

describe('formatSessionEndpointError', () => {
  it('generates a string for a session endpoint error response with an "errors" key', () => {
    const response = {errors: {email: ['is invalid']}};
    expect(formatSessionEndpointError(response)).toEqual('Email is invalid');
  });

  it('returns the error message string for a session endpoint error response that has a string "error" key', () => {
    const response = {error: 'Your request is bad, and you should feel bad.'};
    expect(formatSessionEndpointError(response)).toEqual('Your request is bad, and you should feel bad.');
  });

  it('returns a default message if the response has a non-string "error" key', () => {
    const response = {error: { foo: 'bar' } };
    expect(formatSessionEndpointError(response)).toEqual(
      'Something went wrong - check the information you entered and try again.'
    );
  });

  it('returns a default message if the response does not have an "errors" key', () => {
    const response = {foo: 'bar'};
    expect(formatSessionEndpointError(response)).toEqual(
      'Something went wrong - check the information you entered and try again.'
    );
  });

  it('returns a default message if the responses "errors" key is empty', () => {
    const response = {errors: {}};
    expect(formatSessionEndpointError(response)).toEqual(
      'Something went wrong - check the information you entered and try again.'
    );
  });

  it('returns a default message if the responses "errors" key\'s first entry is empty', () => {
    const response = {errors: {email: []}};
    expect(formatSessionEndpointError(response)).toEqual(
      'Something went wrong - check the information you entered and try again.'
    );
  });
});
