import { buildCredentialStorage } from '../credential_storage';

describe('buildCredentialStorage', () => {
  const stubbed_token_data = {token_type: 'bearer', access_token: '1234567890'};
  const stubbed_user_credentials = {email: 'test@example.com', password: 'minitest'};

  describe('getUserCredentials', () => {
    it('returns the token_data object if present', () => {
      const credential_storage = buildCredentialStorage();

      expect.hasAssertions();
      return credential_storage.setUserCredentials(stubbed_user_credentials).then(() => {
        return expect(credential_storage.getUserCredentials()).resolves.toEqual(stubbed_user_credentials);
      });
    });

    it('returns null if data is not present in memory', () => {
      const credential_storage = buildCredentialStorage();

      expect.hasAssertions();
      return expect(credential_storage.getUserCredentials()).resolves.toEqual(null);
    });
  });

  describe('setUserCredentials', () => {
    it('sets the value and returns a resolving Promise', () => {
      const credential_storage = buildCredentialStorage();

      expect.assertions(2); // nested async calls, explicit assertion count ensures that all of them are running
      return credential_storage.setUserCredentials(stubbed_user_credentials).then((val) => {
        expect(val).toEqual(true); // return value not important
        expect(credential_storage.getUserCredentials()).resolves.toEqual(stubbed_user_credentials);
      });
    });
  });

  describe('resetUserCredentials', () => {
    it('removes the value and returns a resolving Promise', () => {
      const credential_storage = buildCredentialStorage(stubbed_token_data);

      expect.assertions(3); // nested async calls, explicit assertion count ensures that all of them are running
      return credential_storage.setUserCredentials(stubbed_user_credentials).then(() => {
        expect(credential_storage.getUserCredentials()).resolves.toEqual(stubbed_user_credentials);

        credential_storage.resetUserCredentials().then((val) => {
          expect(val).toEqual(true); // return value not important
          expect(credential_storage.getUserCredentials()).resolves.toEqual(null);
        });
      });
    });
  });

  describe('getToken', () => {
    it('returns the token_data object if present', () => {
      const credential_storage = buildCredentialStorage(stubbed_token_data);

      expect.hasAssertions();
      return expect(credential_storage.getToken()).resolves.toEqual(stubbed_token_data);
    });

    it('returns null if data is not present in memory', () => {
      const credential_storage = buildCredentialStorage();

      expect.hasAssertions();
      return expect(credential_storage.getToken()).resolves.toEqual(null);
    });
  });

  describe('setToken', () => {
    it('sets the value and returns a resolving Promise', () => {
      const credential_storage = buildCredentialStorage();

      expect.assertions(2); // nested async calls, explicit assertion count ensures that all of them are running
      return credential_storage.setToken(stubbed_token_data).then((val) => {
        expect(val).toEqual(true); // return value not important
        expect(credential_storage.getToken()).resolves.toEqual(stubbed_token_data);
      });
    });
  });

  describe('resetToken', () => {
    it('removes the value and returns a resolving Promise', () => {
      const credential_storage = buildCredentialStorage(stubbed_token_data);

      expect.assertions(2); // nested async calls, explicit assertion count ensures that all of them are running
      return credential_storage.resetToken().then((val) => {
        expect(val).toEqual(true); // return value not important
        expect(credential_storage.getToken()).resolves.toEqual(null);
      });
    });
  });

  describe('resetTokenAndUserCredentials', () => {
    it('removes the value from memory and localStorage, and returns a Promise that resolves', () => {
      const credential_storage = buildCredentialStorage(stubbed_token_data);

      expect.assertions(5); // nested async calls, explicit assertion count ensures that all of them are running
      return credential_storage.setUserCredentials(stubbed_user_credentials).then(() => {
        expect(credential_storage.getUserCredentials()).resolves.toEqual(stubbed_user_credentials);
        expect(credential_storage.getToken()).resolves.toEqual(stubbed_token_data);

        credential_storage.resetTokenAndUserCredentials().then((val) => {
          expect(val).toEqual(true); // return value not important

          expect(credential_storage.getUserCredentials()).resolves.toEqual(null);
          expect(credential_storage.getToken()).resolves.toEqual(null);
        });
      });
    });
  });
});
